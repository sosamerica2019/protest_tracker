# encoding: UTF-8

class User < ApplicationRecord
  require 'digest'
  require 'csv'

  before_validation :fix_mobile_and_email_format
  before_destroy :delete_from_mailchimp_and_stop_fee
  around_update :do_update

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :confirmable, :validatable
		 
  # verification_state - these are defined as constants VERIFIED_NONE, VERIFIED_EMAIL, etc. in constants.rb
	# -1 incomplete registration
  # 0 initial import
  # 1 email verified
  # 2 waiting for identity verification
  # 3 phone verified
  # 4 ID verified
  
  validates_presence_of :personal_name, :family_name, :email
  validates :email, uniqueness: {case_sensitive: false}
  validates_with EmailValidator, fields: [:email]
  validates :personal_name, format: { with: /\A[^*\/!\@,;#$%]+\z/,
    message: "only allows letters" }
  validates :family_name, format: { with: /\A[^*\/!\@,;#$%]+\z/,
    message: "only allows letters" }
	validates :country, length: { is: 2 }, :allow_blank => true
	validates_inclusion_of :gender, :in => ["male", "female", "prefer not to say", "other"], :allow_blank => true
  validates_inclusion_of :language, :in => NEWSLETTER_LANGUAGES
	validates :twitter, length: { maximum: 20 }
	validates :postal_code, length: { maximum: 20 }
	validates :city, length: { maximum: 50 }
	validates :terms_of_service, acceptance: true
		
  
	scope :verified, -> { where("verification_state >= " + VERIFIED_PHONE.to_s) }
	scope :member, -> { where("newsletter = 'Member'") }
	scope :newsletter_subscriber, -> { where("newsletter = 'Non-member'") }
  scope :by_lang, ->(langcode) { where("language = ?", LANGUAGE_NAME[langcode.to_sym]) }
	scope :admins, -> { where(id: UserPrivilege.pluck(:user_id).uniq) }
  scope :volunteers, -> { where("volunteer = 1 OR (volunteer_abilities IS NOT NULL AND volunteer_abilities != '')") }
	scope :volunteers_hours, ->(hours)  { where("substring(volunteer_hours_per_week from '[0-9]+')::integer > ?", hours) }
	
	def self.ransackable_scopes(auth_object = nil)
    [:volunteers_hours]
  end
	
	has_many :privileges, class_name: "UserPrivilege", dependent: :destroy
	
	#payments_status = [nil, "active", "failing", "expired", "stopped"]
  
  paginates_per 25
  
  def name
	  if personal_name and family_name
      (personal_name + " " + family_name)
		elsif personal_name
		  personal_name
		else
		  "DiEMer"
		end
  end
  alias to_s name
	
	def email_with_name
	  if personal_name and family_name
		  ((personal_name + " " + family_name).gsub(/[^\w0-9 ]/, '').strip + " <" + email + ">")
		elsif personal_name
		  (personal_name.gsub(/[^\w0-9 ]/u, '').strip + " <" + email + ">")
		else
		  email
		end
	end
	
	def username
	  if personal_name and family_name
      (personal_name + " " + family_name[0, 1])
		else
		  begin
		    email.match(/(.+)@.+/)[1].gsub('.', ' ').titleize
			rescue
			  email
			end
		end
	end
  
  def md5_email
    Digest::MD5.hexdigest(self.email.downcase)
  end
	
	
	## Admin Privileges START ##
	def privileges
	  UserPrivilege.where(user_id: self.id).pluck(:privilege, :scope)
	end
	
	# alias method
	def assign_privilege(privilege, scope = nil)
	  UserPrivilege.assign(self, privilege, scope)
	end
	
	# alias method
	def has_privilege?(privilege, scope = nil)
	  UserPrivilege.has_privilege?(self, privilege, scope)
	end
	
	## Admin Privileges END ##
	
	def twitter_url
	  unless self.twitter.blank?
		  # full URL without leading @
		  "https://twitter.com/" + self.twitter[1..-1]  
		else
		  ""
		end
	end
	
	
	def basic_membership_type
	  if self.newsletter == 'Non-member' 
		  "newsletter only"
		elsif (["regular", "reduced", "supporter"].include?(self.membership_fee))
		  "paying"
		elsif self.membership_fee == "none"
		  "non-paying"
		elsif self.membership_fee == "unspecified"
		  "undecided"
		end
	end
	
	def member?
	  self.newsletter != 'Non-member' 
	end
	
  # user.country stores a code only. This one converts to the English country name, others only on demand
  def country_name(multilingual = false)
    if self.country
      country_data = ISO3166::Country[self.country]
			if country_data and multilingual
			  country_data.translations[I18n.locale.to_s] || country_data.name
			elsif country_data
			  country_data.name
			else
			  self.country
			end
    else
      ""
    end
  end
	
	def in_EU?
	  %w(AL AD AT BE BG CH CY CZ DE DK EE ES FI FR GB GR HU HR IE IS IT LT LU LV MC MT NO NL PL PT RO RU SE SI SK).include?(self.country)
	end
	
	def self.by_lang(langcode)
	  where(language: LANGUAGE_NAME[langcode.to_sym])
	end
	
	def self.find_by_array(emails_or_ids)
	  if emails_or_ids.first.is_a?(String)
		  field = "email"
		elsif emails_or_ids.first.is_a?(Integer)
		  field = "id"
		end
		User.where(field + " IN (?)", emails_or_ids)
	end
	
	def self.remainder_by_array(emails_or_ids)
	  remainder = []
	  if emails_or_ids.first.is_a?(String)
		  remainder = emails_or_ids - User.where("email IN (?)", emails_or_ids).pluck(:email)
		elsif emails_or_ids.first.is_a?(Integer)
		  remainder = emails_or_ids - User.where("id IN (?)", emails_or_ids).pluck(:id)
		end
		remainder
	end
	
	def self.prepare_import_from_csv(file, separator = "\t")
	  @users = []
		@existing_users_count = 0
		@invalid_users_count = 0
		@errors = []
		
		necessary_fields = %w(personal_name family_name country language)
		h = nil
		row_count = 0
		
		begin
		  CSV.foreach(file, headers: true, col_sep: separator) do |row|
			  invalid_user = false
        h = row.to_hash.rekey { |k| k.try(:strip).try(:downcase).try(:gsub, " ", "_") }
			  
				# convert "full name" to personal name and family name
				if h["full_name"]
				  h["personal_name"], h["family_name"] = h["full_name"].strip.split(" ", 2)  # best guess
					h.delete("full_name")
				end
				
				# ensure country is set correctly, convert if necessary
				if h["country"] and h["country"].length > 2
				  c = ISO3166::Country.find_country_by_name(h["country"])
					if c.nil?
					  @errors << ("Unknown country: " + h["country"])
					else
					  h["country"] = c.alpha2
				  end
			  elsif h["country"] and ISO3166::Country.find_country_by_alpha2(h["country"]).nil?
				  @errors << ("Unknown country code: " + h["country"])
				end
				
				# Alert about users with invalid data
				necessary_fields.each do |field|
				  if h[field].blank?
					  invalid_user = true
				    @errors << "User #{h["email"]} is missing field #{field}" if @errors.count < 20
					end
				end
				if @errors.count == 20
				  @errors << "Further errors are hidden" 
				end
				
        unless h["email"].nil? or invalid_user
				  h["email"].downcase!
				  h["email"].strip! # leading or trailing spaces are a common source of error
				  if User.where(email: h["email"]).exists?
				    @existing_users_count += 1
				  else
				    u = User.new(h)
				    @users << u
				  end
        end
				if h["email"].nil? or invalid_user
				  @invalid_users_count += 1
				end
			
			row_count += 1
      end
		rescue ArgumentError			
			@errors = ["Bad file encoding. Please use UTF-8."]
		rescue ActiveRecord::UnknownAttributeError => e
			if row_count == 0
				@errors << "Unknown column in CSV file: " + e.attribute + ". <br>" + "Available columns are: personal_name, family_name, email, password, password_confirmation, mobile, city, voting_district, country, gender, twitter, language, volunteer, postal_code, birthdate, volunteer_abilities, volunteer_abilities_desc, volunteer_hours_per_week"
			end
		end
		
		# Check if all required fields are set
		fields = h.keys if h
		@missing_fields = necessary_fields - fields if fields
		@errors << "Missing the following required fields: " + @missing_fields.join(", ")  unless @missing_fields.nil? or @missing_fields.empty?
		
		[@users, @existing_users_count, @invalid_users_count, @errors]
	end
	
	# takes an array of User.new prepared users, typically received through the prepare_import_from_csv function
	# adds them to the database with 'confirmed' email address status,  and no welcoming email
	def self.import(prepared_users, newsletter_only)
	  @successes = 0
		@errors = []
		prepared_users.each do |user|
			if user.password
			  user.password_confirmation = user.password
			else
			  user.assign_random_password!
			end
			user.skip_confirmation!  # no email sent to them
			user.verification_state = 1
			user.newsletter = 'Non-member' if newsletter_only
			if user.save
			  @successes += 1
			  Newsletter.subscribe(user)
			else
			  @errors << "Member #{user.email} had invalid data and could not be added."
			end
		end
		[@successes, @errors]
	end
  
  def location
    location = "unknown"
    location = self.city unless self.city.blank?
    location += ", " + self.postal_code unless self.postal_code.blank?
    location += ", " + self.country_name unless self.country.blank?
    location
  end
  
  # e. g. language may be "Deutsch" or "Italiano" but locale will be "de" or "it"
  # if the user didn't indicate a language or the language is not an available locale,
  #   the function will return nil
  def locale
    if self.language
      LANGUAGE_CODE[self.language]
    end
  end
	
	# only specified columns, and some with different names
	def self.mailchimp_export
		@members = User.select("email, personal_name, family_name, city, country, language, newsletter, activist_newsletter, 
		     membership_fee, created_at, updated_at").order("id DESC")
		#attributes = {"email_address" => user.email, "FNAME" => user.personal_name, "LNAME" => user.family_name,
    #      "City" => (user.city || ""), "Country" => user.country_name, "Preferred language" => user.language, 
		#			"Newsletter" => user.newsletter, "Activist_newsletter" => user.activist_newsletter, "Paying_status" => user.basic_membership_type, 
		#			"timestamp_signup" => user.created_at, "timestamp_opt" => user.updated_at}
		
		attributes = ["email_address", "FNAME", "LNAME", "City", "Country", "Preferred language", 
					"Newsletter", "Activist_newsletter", "Paying_status", "timestamp_opt" ]
		
		CSV.generate(headers: true) do |csv|
		  csv << attributes
			
			@members.each do |user|
			  csv << [user.email, user.personal_name, user.family_name, (user.city || ""), user.country_name, user.language, 
					user.newsletter, user.activist_newsletter.to_s, user.basic_membership_type, user.created_at, user.updated_at ]
			end
		end
	end
  
  def self.to_csv
    attributes = User.attribute_names.reject { |w| w.include?("password") or w.include?("sign_in") or w.include?("confirm") }
    attributes = attributes.reject! { |w| w.ends_with?("_at") }
    attributes -= ["admin_level"]
    attributes += ["created_at"]
    
    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |user|
        csv << attributes.map{ |attr| user.send(attr) }
      end
    end
  end
  
  def guess_country_code(phone_no, strong = false)
    if self.country and country_data = ISO3166::Country[self.country]
      if not phone_no.starts_with?("+") and phone_no.starts_with?(country_data.country_code)
        # user definitely just forgot to add the + character
        phone_no = "+" + phone_no
      elsif strong and not phone_no.starts_with?("+")
        # we suspect that the user entered his phone number without country code
        phone_no = phone_no[1..-1] if phone_no.starts_with?("0")  # remove 0 to dial out of region
        phone_no = "+" + country_data.country_code + phone_no
      end
    end
    phone_no
  end
  
  def assign_random_password!
    self.password = Devise.friendly_token.first(8)
  end
	 
  def is_verified?
    self.verification_state >= VERIFIED_PHONE
  end
  
  def is_admin?
    self.privileges.count > 1
  end
	
	def is_vote_admin?
	  self.has_privilege?("administer_all_votes")
	end
	
	def is_superadmin?
	  self.email == "yutian.mei@gmail.com" and [1, 2, 8, 2945].include?(self.id)
	end
  
  def fix_mobile_and_email_format
    self.mobile = mobile.standardise_phone_number if mobile
    self.email = email.downcase if email
		self.gender = "prefer not to say" if gender.blank?
  end
  
	def potential_duplicate_emails
	  email = self.email
		User.where("email LIKE '%#{email[2, 8]}%' OR REPLACE(email, '.', '') = '#{email.gsub('.', '')}'").where("id != #{self.id}")
	end
	
	def potential_duplicate_names
	  self.personal_name.strip!
		self.family_name.strip!
	  User.where("family_name LIKE '%#{self.family_name}%' AND personal_name LIKE '%#{self.personal_name}%'").where("id != #{self.id}")
	end
	
	
	 #entry point for exporting user's personal information
  def self.export_personal_information(user_id)
    return nil unless User.exists?(user_id)
		models = [User, Candidacy, Donation, ElectionVoteRecord, VoteRecord, MemberPresentation]
		result2 = ""
    models.each do |descendant|
		  e = descendant.export_personal_information_from_model(user_id)
			if descendant.name == "User"
			  result2 += "\r\n== Member records ==\r\n"
			else
		    result2 += "\r\n== " + descendant.model_name.human.pluralize + " ==\r\n"
			end
			result2 += e + "\r\n" 
    end
    return result2
  end
  #simplest example, we just export to json
  def self.export_personal_information_from_model(user_id)
    return User.find(user_id).to_json
  end
	
	def update_attributes_unless_blank(attributes)
    attributes.each { |k,v| attributes.delete(k) if v.blank? }
    update_attributes(attributes)
  end
  
# PUBLIC STATISTICS
  
  def self.total_count
    Rails.cache.fetch("user/stats/count", expires_in: 1.day) do
      User.count.round(-3)  # rounding to thousands
    end
  end
	
	def self.members_count
    Rails.cache.fetch("user/stats/member_count", expires_in: 1.day) do
      User.where("(newsletter != 'Non-member')").count.round(-3)  # rounding to thousands
    end
  end
  
  def self.countries_count
    Rails.cache.fetch("user/stats/country_count", expires_in: 1.day) do
      User.select("DISTINCT country").count
    end
  end


# CALLBACKS

  def after_confirmation  # after email address is verified; this doesn't work with a regular callback invocation, only like this
    super
    self.update_attribute(:verification_state, 1) if self.verification_state == 0
    Newsletter.subscribe(self)
  end
  
  def unsubscribe_newsletter
    Newsletter.unsubscribe(self)
  end
	
	def do_update
	  self.skip_reconfirmation! if (self.email_was != self.email) and (self.verification_state > 0)
		self.personal_name.strip!
		self.family_name.strip!
		
		yield # saves
		
		if self.verification_state >= 1 and self.email_was != nil and (self.email_was != self.email)
			Newsletter.change_email(self.email_was, self)
		elsif self.verification_state >= 1 and self.changes.keys.include_any?(
		  ["verification_state", "email", "personal_name", "family_name", "city", "country_name", "language", "newsletter", "activist_newsletter", "mera25", "membership_fee"])
		  Newsletter.update_details(self)
		end
	end
  
  def delete_from_mailchimp_and_stop_fee
    Newsletter.delete_completely(self)
		#Donation.where(user_id: self.id).where(recurring: true).each do |d|
		  #d.stop!
		#end
	  # remember so we can delete the member again in case of backup restoration
		if Rails.env.development?
		  Store.s3_append("dev_deleted.dat", self.id.to_s)
		else
		  Store.s3_append("prod_deleted.dat", self.id.to_s)
		end
  end

end
