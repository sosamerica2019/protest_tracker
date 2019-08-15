class MyDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that your mailer uses the devise views
	
  # Overrides same inside Devise::Mailer
  def confirmation_instructions(record, token, opts={})
	  set_record_locale(record)
    @head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		
		# Use different e-mail templates for normal signup e-mail confirmation 
    # and for newsletter subscriptions.
    if record.member?
      opts[:template_name] = 'confirmation_instructions'
			@preview = I18n.t("general.welcome", name: record.name)
    elsif record.just_signed_petition?
      @petition = Petition.find(record.refer[8..-1].to_i)
      @head_image = @petition.picture_url if @petition and @petition.picture_url
      opts[:template_name] = 'petition_newsletter_instructions'
			opts[:subject] = I18n.t("newsletter.confirm_subject")
    else
      opts[:template_name] = 'newsletter_instructions'
			opts[:subject] = I18n.t("newsletter.confirm_subject")
    end
		
    super
  end

  def reset_password_instructions(record, token, opts={})
	  set_record_locale(record)
    super
  end
	
	
# Internal
	
	def set_record_locale(record)
	  I18n.locale = record.locale || I18n.default_locale
	end

end