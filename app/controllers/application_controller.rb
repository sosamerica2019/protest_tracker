class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: -> { controller_name == 'sessions' && action_name == 'create' }
  
  layout :layout_by_resource
  
  before_action :set_locale
 
  rescue_from ActionController::RoutingError, ActionController::UnknownController, ::AbstractController::ActionNotFound, ActiveRecord::RecordNotFound do |exception|
    logger.info "Not Found: '#{request.fullpath}'. #{exception.class} error was raised: #{exception.message}"
    render 'pages/error_404', status: 404 
  end
 
  def set_locale
    params[:locale] = nil if not I18n.available_locales.include?(params[:locale].try(:to_sym))
    if Rails.env.test?
      I18n.locale = params[:locale] || get_locale_from_user || :en
    else
		  I18n.locale = params[:locale] || get_locale_from_user || get_locale_from_browser || I18n.default_locale
    end
  end
  
  def default_url_options
    { locale: I18n.locale }
  end
  
  def get_locale_from_user
    current_user.locale if current_user
  end
  
  def get_locale_from_browser
    http_accept_language.compatible_language_from(I18n.available_locales)
  end
	
	def cloudflare_country_code
    request.headers['HTTP_CF_IPCOUNTRY']
  end
  
  def layout_by_resource
    c = params[:controller]
    a = params[:action]
    if ["devise/sessions", "devise/confirmations", "devise/passwords", "passwords", "devise/unlocks"].include?(params[:controller]) 
      "picture_background"
		elsif (c == "embed")
		  false
    elsif (c == "pages" and a == "newsletter_thanks")
      "picture_background"
    elsif (c == "pages" and ["newsletter_new", "newsletter_create"].include?(a))
      "external_seamless"
    elsif (c == "registrations") and (a == 'new' or a == 'create')
      "external_seamless"
    elsif (c == "vc" and a == "view") or (c == "member_presentations" and a == "full_preview") or (c == "pages" and !["index", "chat", "goodies", "contact_cc_form", "contact_diem25", "budget", "policy_work"].include?(a))
      "external_seamless"
    elsif (c == "dscs" and a == "public_index") or (c == "votes" and a == "public_show") or (c == "petitions" and a == "show")
      "external_seamless"
    elsif (c == "donations" and ["new", "new_earmarked", "new_membership", "create", "thanks", "optin_call", "optin_submit"].include?(a))
      "external_seamless"
    else
      "application"
    end
  end
  
protected
  def require_verified!
    authenticate_user! if current_user.nil?
    unless current_user.is_verified?
      flash[:alert] = I18n.t('verify.need2')
		  redirect_to "/"
		end
  end
	
	def require_privilege(privilege, scope = nil)
	  authenticate_user! if current_user.nil?
		#scope = current_user.country if scope.nil? and privilege.includes?("in_country")
		unless current_user.has_privilege?(privilege, scope)
		  flash[:alert] = "This function requires you to have #{privilege} privileges, which you don't have. If you believe you should have it, write to Judith."
		  redirect_to "/"
		end
	end

  def require_admin!  # this requires having more than one admin privilege
    authenticate_user! if current_user.nil?
    if not current_user.is_admin?
			flash[:alert] = I18n.t('general.admin_needed')
		  redirect_to "/"
		end
  end
	
	def require_midlevel_admin!
	  authenticate_user! if current_user.nil?
    if current_user.admin_level.nil? or current_user.admin_level < 5
			flash[:alert] = "This function requires a higher admin level than you currently have."
		  redirect_to "/"
		end
	end
	
	def require_activeadmin_privileges!
	  authenticate_user! if current_user.nil?
    if current_user.has_privilege?("administer_volunteers_in_country", "any") or current_user.has_privilege?("administer_users_in_country", "any")
		  # go!
		else
			flash[:alert] = "You do not currently have ActiveAdmin access. If you believe you should have it, e.g. to administer members or volunteers, write to Judith."
		  redirect_to "/"
		end
	end
	
	def require_l9_admin!
	  authenticate_user! if current_user.nil?
    if current_user.admin_level.nil? or current_user.admin_level < 9
			flash[:alert] = "This function requires a higher admin level than you currently have."
		  redirect_to "/"
		end
	end
	
	def require_impossible!
	  flash[:alert] = "This area is beyond access to anyone currently"
		redirect_to "/"
	end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    "https://diem25.org"
  end
end
