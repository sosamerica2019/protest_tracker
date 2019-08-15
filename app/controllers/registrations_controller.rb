class RegistrationsController < Devise::RegistrationsController
  
  def new
    @country = cloudflare_country_code
    @lang = I18n.locale
    @title = I18n.t('register.headline')
    @description = I18n.t('register.desc1') + " " + I18n.t('register.desc2') 
		@membership_fees = {}
		["regular", "reduced", "none", "newsletter", "supporter"].each do |w|
		  @membership_fees[w] = I18n.t('membership_fees.' + w)
		end
		@refer = params[:refer].gsub(/[^A-z0-9]/, '') if params[:refer]
		
		# super
		build_resource
    yield resource if block_given?

		if params[:user]
		  resource.email = params[:user][:email] if params[:user][:email]
		  resource.personal_name = params[:user][:personal_name] if params[:user][:personal_name]
		  resource.family_name = params[:user][:family_name] if params[:user][:family_name]
			resource.city = params[:user][:city] if params[:user][:city]
			resource.country = params[:user][:country] if params[:user][:country]
		end
		
		if params[:org] == 'mera25'
		  I18n.locale = :el
		  @lang = :el
		  render 'new_mera25', layout: 'mera25'
		else
		  # render the usual
		end
  end
	
	def create
	  # ensure that newsletter subscribers can become full members
		# without getting an 'email exists' error
	  s_params = sign_up_params.merge(newsletter: 'Member')
		I18n.locale = :el if s_params[:mera25]
	  
	  u = User.find_by_email(s_params[:email]) unless s_params[:email].blank?
		if u and (u.newsletter == "Non-member")
		  # newsletter subscriber
			self.resource = u 
      prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
      resource_updated = resource.update_attributes(s_params.merge(created_at: Time.now))
			resource.clean_up_passwords
			if resource.verification_state == 0  # skip email verification
			  resource.confirm if not resource.confirmed?
			  resource.verification_state = 1
			end
			Newsletter.update_details(resource)
		elsif u and u.verification_state == -1  
		  # incomplete registration
			self.resource = u
			prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
			if verify_recaptcha(model: resource, secret_key: ENV['recaptcha_secret_key']) or Rails.env.test?
			  resource_updated = resource.update_attributes_unless_blank(s_params.merge(verification_state: 0))
				resource.send(:generate_confirmation_token)
        Devise::Mailer.confirmation_instructions(resource, resource.instance_variable_get(:@raw_confirmation_token)).deliver_later
			end
		elsif u and s_params[:mera25]
			# DiEMer now registering for MeRA
			# update fields if better content
			self.resource = u
			if resource_updated = resource.update_attributes_unless_blank(mera_params)
			  flash[:notice] = I18n.t("register.mera_successful")
			  render 'mera25_welcome', layout: 'mera25' and return
			end
	  elsif u and !u.invitation_created_at.nil? and u.invitation_accepted_at.nil?
		  # this person was invited, but didn't use the invite link
			# remove the invited user and register this one instead
			u.destroy
			build_resource(s_params) 
		  resource.save if verify_recaptcha(model: resource, secret_key: ENV['recaptcha_secret_key']) or Rails.env.test?
		elsif u
		  # previous complete registration
		  flash[:alert] = I18n.t("register.have_account_recover_password")
			redirect_to new_user_password_path and return
		else
		  # new registration
		  build_resource(s_params) 
		  resource.save if verify_recaptcha(model: resource, secret_key: ENV['recaptcha_secret_key']) or Rails.env.test?
		end
		
		# copying from original code because of extra sign_in call
		
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
				sign_in(resource) #added
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
				sign_in(resource) #added
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
			if resource.mera25.nil?
			  render 'new'
			else
			  render 'new_mera25', layout: 'mera25'
			end
    end
	end	
  
  def update
    super
    # since this is the standard after-save method, let's also update the locale
    I18n.locale = current_user.locale if current_user.language_changed? and !current_user.language.blank? and current_user.locale
  end
	
	# DELETE /resource
  def destroy
	  if params[:password] and current_user.valid_password?(params[:password])
      resource.destroy
      Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name)
      set_flash_message :notice, :destroyed if is_flashing_format?
      yield resource if block_given?
      respond_with_navigational(resource){ redirect_to after_sign_out_path_for(resource_name) }
		else
		  flash[:alert] = I18n.t("register.cancel_account_need_password")
			redirect_to edit_user_registration_path
		end
  end

  private
  
  def after_sign_up_path_for(resource)
	  if resource.is_mera25_member?
		  mera25_welcome_path
		else
      flash[:notice] = nil
		  flash[:extra] = I18n.t("register.one_more_step")
		  #"/users/sign_in?locale=" + (params[:locale] || "en")
		  "/membership/new?locale=" + (params[:locale] || resource.locale.to_s || "en")
		end
  end
  
  def after_inactive_sign_up_path_for(resource)
	  if resource.is_mera25_member?
		  mera25_welcome_path
		else
      flash[:notice] = nil
		  flash[:extra] = I18n.t("register.one_more_step")
		  #"/users/sign_in?locale=" + (params[:locale] || "en")
		  "/membership/new?locale=" + (params[:locale] || resource.locale.to_s || "en")
		end
  end
  
  def sign_up_params
    prepare_volunteer_params_for_db
    params.require(:user).permit(:personal_name, :family_name, :email, :password, :password_confirmation, :mobile, :city, :country, :gender, :twitter, :language, :volunteer, :postal_code, :birthdate, :volunteer_abilities, :volunteer_abilities_desc, :volunteer_hours_per_week, :refer,
		:full_legal_name, :voting_district, :address, :profession, :willing_local, :which_local, :willing_thematic, :which_thematic, :mera25, :other_party, :terms_of_service)
  end
	
	def mera_params
	  prepare_volunteer_params_for_db
    params.require(:user).permit(:city, :twitter, :volunteer, :postal_code, :birthdate, :volunteer_abilities, :volunteer_abilities_desc, :volunteer_hours_per_week, :refer, :full_legal_name, :voting_district, :address, :profession, :willing_local, :which_local, :willing_thematic, :which_thematic, :mera25, :other_party)
	end

  def account_update_params
    prepare_volunteer_params_for_db
    params.require(:user).permit(:personal_name, :family_name, :email, :password, :password_confirmation, :current_password, :mobile, :city, :country, :gender, :twitter, :language, :volunteer, :postal_code, :birthdate, :volunteer_abilities, :volunteer_abilities_desc, :volunteer_hours_per_week, :refer,
		:full_legal_name, :voting_district, :address, :profession, :willing_local, :which_local, :willing_thematic, :which_thematic, :mera25, :other_party)
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
	
	def set_flash_message!(key, kind, options = {})
    set_flash_message(key, kind, options)
  end
	
	def translation_scope
    'devise.registrations'
  end
	
	def update_resource_no_pw(resource, params)
    resource.update_without_password(params)
  end
  
end
