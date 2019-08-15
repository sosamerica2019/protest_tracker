# encoding: UTF-8

class PagesController < ApplicationController

  before_action :authenticate_user!, :except => [:budget, :members, :mera25, :create_mera25, :mera25_welcome, :team, :newsletter_new, :newsletter_create, :newsletter_thanks, :email_newsletter_invitation]
  before_action :require_verified!, :only => [:chat]

	def error_404
	  logger.info "Page Not Found: '#{request.fullpath}'. Route not found."
		render status: 404
	end
	
	def budget
	  @title = I18n.t("budget.title")
		if current_user.nil?
		  redirect_to new_donation_path
		end
	end
	
	def change_language
	  success = false
		if params[:fname] and params[:lname] and params[:email] and params[:lang] and ALL_LANGUAGE_CODES.include?(params[:lang])
		  u = User.find_by_email(params[:email].downcase)
			if u and u.personal_name == params[:fname] and u.family_name == params[:lname]
			  u.update(language: LANGUAGE_NAME[params[:lang].to_sym])
			  success = true
			end
		end
		if success
		  I18n.locale = u.locale
		  flash[:notice] = I18n.t("account.update_language_success")
		  render 'pages/newsletter_thanks', layout: "picture_background"
		else
		  render plain: "Error"
		end
	end
	
	def contact_cc_form
	  @title = I18n.t("contact.title")
	end
	
	def contact_cc
	  UserMailer.contact_cc(current_user, params[:subject], params[:body]).deliver_later
		flash[:notice] = I18n.t("contact.sent")
		redirect_to :dashboard
	end
	
	def contact_diem25
	  if params[:subject] and params[:body]
		  if params[:addressee] == 'local'
			  Newsletter.create_local_area_draft(current_user, params[:subject], ActionController::Base.helpers.simple_format(params[:body]))
				flash[:notice] = I18n.t("contact_all.local_queued")
			else
		    UserMailer.contact_diem25(current_user, params.to_unsafe_hash).deliver_later
		    flash[:notice] = I18n.t("contact.sent")
		  end
		  redirect_to :dashboard
		else
		  @title = I18n.t("contact_all.title")
		end
	end
	
	def email_newsletter_invitation
	  @from = params[:from]
		if @from.nil? or (@from and @from.include?("@gmail.com"))
		  # show web form
		elsif @from
		  redirect_to "mailto:?subject=&body=Hi%2C%0A%0AI'm%20subscribed%20to%20DiEM25's%20(Democracy%20in%20Europe%20Movement)%20newsletter.%20They%20are%20an%20interesting%20transnational%20movement%2C%20set%20to%20change%20Europe%2C%20and%20worth%20watching%20out%20for.%20I%20recommend%20you%20also%20subscribe%20to%20their%20updates!%20Go%20to%20https%3A%2F%2Finternal.diem25.org%2Fnewsletter%20to%20do%20so.%0A%0ACheers!"
		end
	end
	
	def send_email_newsletter_invitation
	  # send
	end
	
	def export_my_data
	  if UserMailer.export_data(current_user, User.export_personal_information(current_user.id)).deliver_later
		  flash[:notice] = "All data that is associated with your DiEM25 membership has been exported and sent to your email address. To also download your forum activity, please go to your Forum settings, Activity tab, and click 'Download all' there."
		else
		  flash[:alert] = "There was an error exporting your data; please contact volunteer@diem25.org for technical help."
		end
		redirect_to :dashboard
	end
	
  def index
	  @news = News.to_show_for_user(current_user)
	  @events = Event.to_show.between_times(Time.now - 1.day, Time.now + 60.days).by_importance.limit(5)
		@latest_fundraisers = Fundraising.where("created_at > ?", Time.now - 30.days).where("earmark NOT IN (?)", ["belgium", "czech", "germany", "nederland", "uk"])
		@latest_dscs = Dsc.shown_public.except_national.order("created_at DESC").limit(5)
		@latest_topics = Discourse.get_latest_topics(5)
	
		@referenda_active = Vote.in_progress.where("vote_type IN (?)", current_user.shown_vote_types).order("expiry_date ASC, id ASC")
		@elections_active = Election.to_show_publicly_active.order("vote_end DESC").all
    if (not @referenda_active.empty?) and (@referenda_active.all? { |v| (v.created_at < current_user.created_at) and (v.is_open?) and !(current_user.has_active_token?(v)) and !(current_user.date_of_vote_on(v)) })
      flash[:notice] = I18n.t("voting.too_new_to_vote")
      @too_new = true
		else
      # ugly sort
      unvoted_referenda = []
      voted_referenda = []
      @referenda_active.each do |r|
        needs_to_vote = current_user.has_active_token?(r)
        if needs_to_vote
          unvoted_referenda << r
        else
          voted_referenda << r
        end
      end
      @referenda_active = unvoted_referenda + voted_referenda 
    end
  end
  
  def members
    @presentations = MemberPresentation.get_good_mix(I18n.locale)
    @title = I18n.t('pages.members')
    @description = I18n.t('pages.members_desc', :member_count => User.members_count, :country_count => User.countries_count)
    respond_to do |format|
      format.html
      format.json { render json: @presentations.to_json(:only => ["id", "namedesc", "quote", "pic_url"]) }
    end
  end
	
	# Anyone (registered or not) joining MeRA25, with DiEM25 being a second step
	# MeRA25: step 1
	def mera25
	  # combined signup for DiEMers and non-DiEMers
		# through multi-step
		# this shows the start page of the process
	  I18n.locale = :el
		@user = current_user || User.new
		if current_user and current_user.is_mera25_member?
		  # no signup needed
			redirect_to mera25_welcome_path, layout: 'picture_background' and return
		else
		  @user.full_legal_name = @user.name
		  @user.language = LANGUAGE_NAME[I18n.locale]
		  @user.refer = params[:refer].gsub(/[^A-z0-9]/, '') if params[:refer]
		  render layout: 'mera25'
		end
	end
	
	# MeRA25: step 2 (form submit from above)
	def create_mera25
	  bad_validation = false
		@user = current_user
		
		# for existing and logged-in members
	  if current_user
    
		  # name them a MeRA member and update all details
		  if @user.update_attributes(party_params.merge(:mera25 => 'member'))
		    render 'mera25_welcome', layout: 'mera25' and return
			else
			  bad_validation = true
			end
		
		# for existing non-logged-in members (possibly fake)
		elsif User.where(email: params[:user][:email]).exists?
  
		  # update fields if better content
		  @user = User.find_by_email(params[:user][:email])
			if @user.update_attributes_unless_blank(party_params.merge(:mera25 => 'member'))
			  if @user.verification_state == -1  # double registration for MeRA25 without DiEM25 registration
				  flash[:notice] = I18n.t("register.mera_successful_now_diem25")
				  @membership_fees = {}
		      ["regular", "reduced", "none", "newsletter", "supporter"].each do |w|
		        @membership_fees[w] = I18n.t('membership_fees.' + w)
	    	  end
				  @just_registered = true
				  @lang = :el
				  render 'devise/registrations/new_mera25', layout: 'mera25' and return
				else
			    flash[:notice] = I18n.t("register.mera_successful")
			    render 'mera25_welcome', layout: 'mera25' and return
				end
			else
			  bad_validation = true
			end
		
		# for non-members
		else
		  # set temporary password etc, set temp flag, and ask to join DiEM25
			
			@user = User.create_temp_user(party_params.merge(:mera25 => 'member', :email => params[:user][:email]))
		  if @user.persisted?
			  flash[:notice] = I18n.t("register.mera_successful_now_diem25")
				@membership_fees = {}
		    ["regular", "reduced", "none", "newsletter", "supporter"].each do |w|
		      @membership_fees[w] = I18n.t('membership_fees.' + w)
	    	end
				@just_registered = true
				@lang = :el
				
				render 'devise/registrations/new_mera25', layout: 'mera25'
			else
			  bad_validation = true
			end
			
		end
		render :mera25, layout: 'mera25' if bad_validation
	end
	
	def mera25_welcome
	  @user ||= current_user  if current_user and current_user.is_mera25_member?
	  unless @user
		  redirect_to :mera25 and return
		else
	    render layout: 'mera25'
		end
	end
	
	
	# For existing users joining MeRA25
	
	def join_mera25_form
	  I18n.locale = :el
		@user = current_user
		@user.full_legal_name = @user.name
		render layout: 'mera25'
	end
	
	def join_mera25
	  I18n.locale = :el
	  @user = current_user
		if @user.update_attributes(party_params.merge(:mera25 => 'member'))
		  flash[:notice] = I18n.t("register.mera_successful")
			redirect_to :dashboard
		else
		  render :join_mera25_form, layout: 'mera25'
		end
	end
	
	# New newsletter subscribers
  
  def newsletter_new
    if current_user
		  flash[:notice] = I18n.t("newsletter.already_subscribed")
			redirect_to :dashboard
		else 
		  @user = User.new(language: LANGUAGE_NAME[I18n.locale])
			@user.email = params[:user][:email] if params[:user] and params[:user][:email]
		  if params[:org] == 'mera25'
		    @h2_title = "ΜέΡΑ25 & DiEM25 Newsletter"
			  @org = 'mera25'
	   	else
		    @h2_title = "DiEM25 Newsletter"
		  end
      @title = I18n.t("newsletter.headline")
      @description = I18n.t("newsletter.desc1a").gsub("__", "") + " " + I18n.t('newsletter.desc2').gsub("__", "")
		  @refer = params[:refer].gsub(/[^A-z0-9]/, '') if params[:refer]
		end
  end
  
  def newsletter_create
	  if User.find_by_email(params[:user][:email].downcase)
		  flash[:notice] = I18n.t("newsletter.already_subscribed")
			redirect_to :new_newsletter_subscription
		else
      @user = User.new(sign_up_params)
      @user.assign_random_password!
      #@user.skip_confirmation!
		  #@user.verification_state = 1
		  @user.newsletter = "Non-member"
      if @user.save
        # Newsletter.subscribe(@user)  # need to wait till after email verification now!
			  redirect_to thanks_newsletter_subscription_url
		  else
		    render :newsletter_new
		  end
		end
  end
	
  def newsletter_resubscribe
	  if Newsletter.resubscribe(current_user) == "unsuccessful"
		  Store.increase("resubscribe_fail_count")
		  flash[:alert] = I18n.t("newsletter.resubscribe_failed")
		else
		  Store.increase("resubscribe_count")
		  flash[:notice] = I18n.t("newsletter.resubscribed")
		end
    redirect_to :dashboard		
	end
  
  def newsletter_thanks
  end
  
  def share_data_with_es
    u = current_user
    redirect_to "https://our.europeanspring.net/users/sign_up?u[email]=#{u.email}&u[personal_name]=#{u.personal_name}&u[family_name]=#{u.family_name}&u[language]=#{u.language}&u[country]=#{u.country}&u[postal_code]=#{u.postal_code}&u[city]=#{u.city}&u[party]=diem25"
  end
  
  def team
  end
  
  def chat
    @chat_code = "lrmr"
    @chat_start = Time.parse("2016-11-12 12:30 +01")
    @chat_end  = Time.parse("2016-11-12 14:00 +01")
    @chat_message = "Our next chat will be with CC member Lorenzo Marsili on Saturday November 12 at 12:30 CET."
    
    @now = Time.now.between?(@chat_start - 15.minutes, @chat_end)
  end
  
  def goodies
  end

private
	
	def party_params
	  prepare_volunteer_params_for_db
    params.require(:user).permit(:mobile, :city, :postal_code, :birthdate, :full_legal_name, :voting_district, :address, :profession, :willing_local, :which_local, :willing_thematic, :which_thematic, :volunteer_abilities, :other_party, :refer, :terms_of_service)
	end

  def sign_up_params
    params.require(:user).permit(:personal_name, :family_name, :email, :language, :refer, :terms_of_service)
  end  
	
	def prepare_volunteer_params_for_db
    abilities = []
    params.each do |key, value|
      if key.starts_with?("volunteer_") and key != "volunteer_hours_per_week" and key != "volunteer_abilities_desc" and value == "1"
        abilities << key[10..-1]
      end
    end
    params[:user][:volunteer_abilities] = abilities.join(", ") if params[:user]
  end
  
end
