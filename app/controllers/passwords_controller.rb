class PasswordsController < Devise::PasswordsController

  # POST /user/password
  def create
    user = User.find_by_email(params[:user][:email].downcase)
		if user.nil?
		  flash[:alert] = I18n.t("devise.passwords.email_not_found")
			redirect_to new_user_password_path and return
		elsif user.newsletter == "Non-member"
		  flash[:alert] = I18n.t("devise.passwords.newsletter_only")
			redirect_to new_user_registration_path(user: {email: params[:user][:email].downcase}) and return
		elsif user.verification_state == -1  
		  # incomplete registration
			flash[:alert] = I18n.t("devise.passwords.incomplete_registration")
			redirect_to new_user_registration_path(user: {email: params[:user][:email].downcase}) and return
		
		else
		  # code from super
		  self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?

      if successfully_sent?(resource)
        respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
      else
        respond_with(resource)
      end
		end
  end
	

  protected

    def after_resetting_password_path_for(resource)
      resource.confirm! unless resource.confirmed?
      if resource.verification_state == 0
        resource.verification_state = 1 
        resource.save!
      end
      Devise.sign_in_after_reset_password ? after_sign_in_path_for(resource) : new_session_path(resource_name)
    end
  
end
