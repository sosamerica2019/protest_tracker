class Newsletter
  require 'digest'

  def self.change_email(old_email, user)
		unless Rails.env.test?
		  begin
		    Gibbon::Request.lists(ENV['mailchimp_list']).members(Digest::MD5.hexdigest(old_email.downcase)).delete
		  rescue Gibbon::MailChimpError
		    # It's okay, user probably wasn't subscribed
			  # Users are only subscribed IF: a) they are imported old users or b) they are new users who have verified their email address
		  end
		
		  result = Newsletter.subscribe(user)
		end
	end
	
	def self.create_local_area_draft(user, subject, text_body)
	  success = false
	  unless Rails.env.test?
		recipients = {
      list_id: ENV['mailchimp_list'],
      segment_opts: {
        match: "any",
        conditions: [
          {
          condition_type: "TextMerge",
          field: "MMERGE5",
          op: "contains",
          value: user.city
          }
        ]
      }
    }
    settings = {
      subject_line: subject,
      title: "Message to #{user.city} by #{user.name}",
      from_name: "DiEM25 Member #{user.name}",
      reply_to: "info@diem25.org",
			template_id: 69
    }
    body = {
      type: "regular",
      recipients: recipients,
      settings: settings,
    }

    begin
			campaign = Gibbon::Request.campaigns.create(body: body)
			if campaign and campaign.body and id = campaign.body["id"]   # campaign created, now add the text
			  body = {
          template: {
            id: 69,
            sections: {
              "body" => text_body
            }
          }
        }
				Gibbon::Request.campaigns(id).content.upsert(body: body)
				success = true
			end
    rescue Gibbon::MailChimpError => e
      puts "Houston, we have a problem: #{e.message} - #{e.raw_body}"
    end
		end
		success
	end
	
	# returns one of "not in system", "unsubscribed", "subscribed", "unmessaged", "unopened", "all okay"
	def self.get_status(email)
	  status = "not in system"
    d = Digest::MD5.hexdigest(email.downcase)
		begin
    i = Gibbon::Request.lists(ENV['mailchimp_list']).members(d).retrieve(params: {"fields" => "status,timestamp_opt"})
		status = i.body["status"] if i
		new_user = (Time.parse(i.body["timestamp_opt"]) > (Time.now - 1.month)) if i
		if status == "subscribed" and not new_user    # go into more detail
		  a = Gibbon::Request.lists(ENV['mailchimp_list']).members(d).activity.retrieve(params: {"fields" => "activity.action,activity.timestamp"})
			if a and a.body and a.body["activity"]
			  last_message = a.body["activity"].first  # given in opposite chronological order
				if Time.parse(last_message["timestamp"]) < (Time.now - 1.month)
				  status = "unmessaged"
				elsif last_message["action"] == "open" or last_message["action"] == "click"
				  status = "all okay"
				else
				  last_opened = a.body["activity"].index{ |el| (el["action"] == "open") or (el["action"] == "click") }
					last_opened ||= 0
					last_opened += 1   # first index is 0
				  count_sents = a.body["activity"][0..5].count{ |el| el["action"] == "sent" } if last_opened > 3
					count_sents ||= 0
				  if last_opened > 3 and count_sents > 3   # has received emails but not opened them in a while
				    status = "unopened"
          else
					  status = "all okay"
					end
				end
			end
		end
		rescue Gibbon::MailChimpError => e
		  # probably not in system
		end
		status
  end
	
	def self.is_subscribed?(email)
	  subscribed = false
		d = Digest::MD5.hexdigest(email.downcase)
		begin
      i = Gibbon::Request.lists(ENV['mailchimp_list']).members(d).retrieve(params: {"fields" => "status,timestamp_opt"})
		  if i and i.body["status"] == 'subscribed'
		    subscribed = true
		  end
		rescue Gibbon::MailChimpError => e
		  # probably not in system
		end
		subscribed
	end
	
	def self.last_newsletters(email)
	  d = Digest::MD5.hexdigest(email.downcase)
	  a = Gibbon::Request.lists(ENV['mailchimp_list']).members(d).activity.retrieve
		if a and a.body and a.body["activity"]
		  emails = a.body["activity"].keep_if { |el| el["action"] == "sent" }
		else
		  emails = []
		end
		emails
	end
	
	def self.last_sent_to(email)
	  d = Digest::MD5.hexdigest(email.downcase)
	  a = Gibbon::Request.lists(ENV['mailchimp_list']).members(d).activity.retrieve
	  email = a.body["activity"].detect{ |el| el["action"] == "sent" }
	  t = Time.parse(email["timestamp"])
	end
	
	# retrieves 
	def self.link(campaign_id)
	  Rails.cache.fetch("newsletters/#{campaign_id}/url", expires_in: 1.year) do
	    begin
			  c = Gibbon::Request.campaigns(campaign_id).retrieve(params: {fields: "long_archive_url"})
			  if c and c.body
			    c.body["long_archive_url"]
			  else
			    "Bad campaign ID"
			  end
		  rescue Gibbon::MailChimpError
		    # probably not in system
			  "Bad campaign ID"
		  end	
		end
	end
  
  # Many members haven't responded to the after-import email, probably because it went into their
  # spam folder. This function reminds them to verify their accounts by resending the same email 
  # (with a new password and confirmation token because we lost access to the old ones).
  def self.remind_imported_members(count, offset)
    # u_n = User.where("email LIKE 'yutian.mei%'").where(verification_state: 0).first  # Test user
    
    Rails.logger.level = 3
    # For all as-yet unverified users with IDs in the given range
    User.where(verification_state: 0).where("id > ?", offset).where("id < ?", offset + count).each do |u_n|
      # generate a new password and confirmation token because the current ones are inaccessible
      password = u_n.assign_random_password!
      u_n.skip_confirmation_notification!
      u_n.send :generate_confirmation_token
      # now save and get the new confirmation token
      saved = u_n.save
      email_token = u_n.instance_variable_get(:@raw_confirmation_token)
      # set locale for letter
      if u_n.locale and I18n.available_locales.include?(u_n.locale)
        I18n.locale = u_n.locale 
      else
        I18n.locale = :en
      end
      # send letter
      UserMailer.after_import_email(u_n, password, email_token).deliver_now if saved
    end
  end

  def self.subscribe(user)
    # no longer saving all fields to Mailchimp, in order to protect privacy
    result = ""
		unless Rails.env.test? or user.is_guest?
      begin
        result = Gibbon::Request.lists(ENV['mailchimp_list']).members(user.md5_email).upsert(
          body: {"email_address" => user.email, "status" => "subscribed", "merge_fields" => {"FNAME" => user.personal_name, "LNAME" => user.family_name,
          "MMERGE5" => (user.city || ""), "MMERGE6" => user.country_name, "MMERGE9" => user.language, 
					"MMERGE4" => user.newsletter, "MMERGE10" => user.activist_newsletter.to_s, "MMERGE11" => user.basic_membership_type, "MMERGE12" => user.party_membership}, 
					"timestamp_signup" => user.created_at.strftime("%F %T"), "timestamp_opt" => user.updated_at.strftime("%F %T")}
        )
      rescue Gibbon::MailChimpError => e
			  if e and e.raw_body and e.raw_body.include?("Compliance State")
			    # This is someone who previously unsubscribed, so send him a message to resubscribe
					result = Newsletter.resubscribe(user)
				else
				  result = "unsuccessful"
				end
      end
    end
		result
  end
	
	def self.resubscribe(user, pending = true)
	  result = ""
		if pending
		  status = "pending"
		else
		  status = "subscribed"
		end
		unless Rails.env.test? or user.is_guest?
		  begin
	      result = Gibbon::Request.lists(ENV['mailchimp_list']).members(user.md5_email).upsert(
          body: {"email_address" => user.email, "status" => status})
			rescue Gibbon::MailChimpError
			  result = "unsuccessful"
			end
		end
		result
	end
  
  def self.unsubscribe(user)
	  email = if user.is_a?(User)
		  user.email
		elsif user.is_a?(String)
			user
		end
		md5_email = Digest::MD5.hexdigest(email.downcase)
	  begin
      Gibbon::Request.lists(ENV['mailchimp_list']).members(md5_email).update(body: { status: "unsubscribed" }) unless Rails.env.test?
		rescue Gibbon::MailChimpError
		  # It's okay, user probably wasn't subscribed
			# Users are only subscribed IF: a) they are imported old users or b) they are new users who have verified their email address
		end
  end
  
  def self.delete_completely(user)
    begin
		  Gibbon::Request.lists(ENV['mailchimp_list']).members(user.md5_email).delete unless Rails.env.test?
		rescue Gibbon::MailChimpError
		  # It's okay, user probably wasn't subscribed
			# Users are only subscribed IF: a) they are imported old users or b) they are new users who have verified their email address
		end
  end
  
  def self.update_details(user)
	  result = ""
    unless Rails.env.test? or user.is_guest?
      begin
        result = Gibbon::Request.lists(ENV['mailchimp_list']).members(user.md5_email).upsert(
          body: {"email_address" => user.email, "status" => "subscribed", "merge_fields" => {
					"FNAME" => user.personal_name, "LNAME" => user.family_name,
          "MMERGE5" => (user.city || ""), "MMERGE4" => user.newsletter, "MMERGE6" => user.country_name, "MMERGE9" => user.language,
					"MMERGE10" => user.activist_newsletter.to_s, "MMERGE11" => user.basic_membership_type, "MMERGE12" => user.party_membership}}
        )
      rescue Gibbon::MailChimpError
        # This may be someone who unsubscribed or so
				result = "unsuccessful"
      end 
    end
		result
  end
  
  # just for console use currently
  
  def self.check_info_for(email)
    require 'digest'
    d = Digest::MD5.hexdigest(email.downcase)
    Gibbon::Request.lists(ENV['mailchimp_list']).members(d).retrieve
  end

end
