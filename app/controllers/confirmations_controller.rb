class ConfirmationsController < Devise::ConfirmationsController

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message!(:notice, :confirmed)
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      flash[:notice] = "Your account is already confirmed. Please login."
      redirect_to '/users/sign_in'
    #else
      #respond_with_navigational(resource.errors, status: :unprocessable_entity){ render :new }
    end
  end

  private

  def after_confirmation_path_for(resource_name, resource)
	  I18n.locale = resource.locale || I18n.default_locale
    if resource.member?
		  dashboard_url
		else
		  thanks_newsletter_subscription_url
		end
  end

end