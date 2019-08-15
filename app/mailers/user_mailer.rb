class UserMailer < ApplicationMailer
  default from: "DiEM25 <info@diem25.org>"
  layout 'diem25_mail'
	helper :donations
	helper :links
	helper ApplicationHelper
	
	def admin_message(to, subject, body)
    @body = body
    mail(:from => "DiEM25 <help@diem25.org>", :to => to, :subject => subject)
  end
	
	def confirmed_event(event)
	  @event = event
		@user = event.user
		subject = I18n.t("events.approved_mail.subject")
		mail(:from => "DiEM25 <help@diem25.org>", :reply_to => "DiEM25 <help@diem25.org>", :to => @user.email_with_name, :subject => subject)
	end
	
	def confirmed_verification(user)
	  @user = user
		subject = I18n.t("verify.success_email.title")
		mail(:from => "DiEM25 <help@diem25.org>", :reply_to => "DiEM25 <help@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def donation_thanks(donation)
		@head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@donation = donation
		subject = I18n.t("donations.thanks_email.subject")
		mail(:from => "DiEM25 <help@diem25.org>", :reply_to => "DiEM25 <help@diem25.org>", :to => donation.email, :subject => subject)
	end
	
	def election_reminder(user)
	  @head_image = "none" # "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@user = user
		subject = I18n.t("elections.vital")
		@preview = I18n.t("elections.not_voted_cc_yet", name: user.personal_name)
		mail(:from => "DiEM25 <voting@diem25.org>", :reply_to => "DiEM25 <voting@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def export_data(user, data)
	  @user = user
		@data = data
		mail(:from => "DiEM25 <info@diem25.org>", :to => user.email, :subject => "Your data")
	end
	
	def payment_failed(donation)
	  @donation = donation
		recipient = @donation.email
		if @user = donation.user_with_name
		  I18n.locale = @user.locale
			recipient = @user.email_with_name
		else
		  I18n.locale = :en
		end
		subject = I18n.t("donations.failed_email.subject")
		mail(:from => "DiEM25 <info@diem25.org>", :to => recipient, :subject => subject)
	end
	
	def payment_failed_completely(donation)
	  @donation = donation
		recipient = @donation.email
		if @user = donation.user_with_name
		  I18n.locale = @user.locale
			recipient = @user.email_with_name
		else
		  I18n.locale = :en
		end
		subject = try_add_name(I18n.t("donations.stopped_email.subject"), @user)
		mail(:from => "DiEM25 <info@diem25.org>", :to => recipient, :subject => subject)
	end
	
	def payment_now_okay(donation)
	  @donation = donation
		recipient = @donation.email
		if @user = donation.user_with_name
		  I18n.locale = @user.locale
			recipient = @user.email_with_name
		else
		  I18n.locale = :en
		end
		subject = I18n.t("donations.now_okay_email.subject")
		mail(:from => "DiEM25 <info@diem25.org>", :to => recipient, :subject => subject)
	end
	
	def payment_reminder(donation)
		@donation = donation
		@user = donation.user_with_name
		I18n.locale = @user.locale
		subject = I18n.t("donations.error")
		mail(:from => "DiEM25 <info@diem25.org>", :to => @user.email_with_name, :subject => subject)
	end
	
	def petition_thanks(signature)
		@signature = signature
		@petition = @signature.petition
	  if signature.user_id
		  @user = User.find(signature.user_id)
			I18n.locale = @user.locale
		else
		  @user = nil
		end
		subject = @petition.title
		@head_image = @petition.picture_url.with_https if @petition.picture_url
		mail(:from => "DiEM25 <info@diem25.org>", :to => signature.email, :subject => subject)
	end
	
  def problematic_presentation(user, problem = "bad pic")
    @user = user
    @problem = case problem
    when "bad pic"
      "Unfortunately your uploaded picture was too low quality after being cropped into the necessary format, or it did not show you."
    when "missing pic"
      "Unfortunately the picture upload did not succeed. Make sure that you have Javascript enabled."
    end
    mail(:from => "DiEM25 <info@diem25.org>", :to => user.email_with_name, :subject => "A problem with your member presentation")
  end
  
  def random_message(user, subject, body)
    @body = body
    mail(:from => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
  end
	
	def reactivate_inactive(user, inactive_since = "recently")
	  @head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@user = user
		I18n.locale = @user.locale
		subject = I18n.t("mail.missed_you", name: user.name)
		@preview = I18n.t("mail.check_out_offer")
		if @user.verification_state == 0
		  @user.send :generate_confirmation_token
      saved = @user.save
      @token =  @user.instance_variable_get(:@raw_confirmation_token)
		end
		@inactive_since = inactive_since
		mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def remind_confirmation(user)
	  @head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@user = user
		I18n.locale = @user.locale
		subject = I18n.t("devise.mailer.confirmation_instructions.subject")
		@preview = @user.personal_name + ", " + I18n.t("devise.failure.unconfirmed")
		@user.send :generate_confirmation_token
    saved = @user.save
    @token =  @user.instance_variable_get(:@raw_confirmation_token)
		mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
  
  def vc_elected(user)
	  @user = user
    subject = "Congratulations! You are now a member of DiEM25's Validating Council"
		@head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@preview = "You have been elected!"
    mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
  end
	
	def vc_not_responded(user)
	  @user = user
		subject = "You were not fast enough..."
		@head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
		@preview = "Sorry, you are not a member of DiEM25's Validating Council"
    mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def vc_continuing(user)
	  @user = user
		subject = "Your time in DiEM25's Validating Council continues"
    mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def vc_time_ended(user)
	  @user = user
		subject = "Thank you for being part of DiEM25's Validating Council"
		mail(:from => "DiEM25 <volunteer@diem25.org>", :reply_to => "DiEM25 <volunteer@diem25.org>", :to => user.email_with_name, :subject => subject)
	end
	
	def contact_cc(user, subject, body)
	  @user = user
		@body = body
	  subject = "[Member-to-CC] " + subject
		mail(:from => "help@diem25.org", :reply_to => user.email_with_name, :to => "cc@diem25.org", :subject => subject)
	end
	
	def contact_info(name, email, subject, body)
	  @body = body
		@name = name
		@email = email
	  mail(from: "Visitor #{name} <info@diem25.org>", reply_to: "#{name} <#{email}>", to: "info@diem25.org", subject: subject)
	end
	
	
	def contact_diem25(user, params)
	  # First: figure out who the email should be addressed to
		target = case params[:addressee]
		when "cc" then "cc@diem25.org"
		when "tech" then "volunteer@diem25.org"
		when "comms" then "comms@diem25.org"
		when "volunteer" then "volunteer@diem25.org"
		when "any" then "info@diem25.org"
		else "info@diem25.org"
		end
		
		if params[:addressee] == 'nc' 
		  # select with NC
		  target = case params[:nc]
			when "be" then "info@be.diem25.org"
			when "de" then "bundeskollektiv@de.diem25.org"
			when "fr" then "diem25_fr_pnc@framalistes.org"
			when "gb" then "info@uk.diem25.org"
			when "gr" then "symboulio@gr.diem25.org"
			when "it" then "territorio@italia.diem25.org,agenda@italia.diem25.org,eventi@italia.diem25.org,stampa@italia.diem25.org,volontari@italia.diem25.org"
			when "nl" then "nc@nl.diem25.org"
			when "cz" then "nc@cz.diem25.org"
			end

		elsif params[:addressee] == 'workgroup'
		  # select which workgroup
			target = case params[:workgroup]
			when "European Spring policies" then "david.adler@diem25.org"
			when "European New Deal" then "newdeal@diem25.org,clerwall@yahoo.fr"
			when "Transparency" then "transparency@diem25.org"
			when "Refugees & Migration" then "refugees@diem25.org"
			when "Constitution" then "constitution@diem25.org"
			when "Tech" then "techpillar@diem25.org"
			when "Labour" then "labour@diem25.org"
			when "Green Transition" then "transition@diem25.org"
			when "national policies" then "info@diem25.org"
			else "david.adler@diem25.org"  # or info@
			end
			
		elsif params[:addressee] == 'dsc'
		  # select which DSC, and send either to the public address or to the coordinators
		  dsc = Dsc.find(params[:dsc])
			target = dsc.public_email
			if target.blank?
			  target = dsc.coordinator_email
			  target += "," + dsc.coordinator2_email unless dsc.coordinator2_email.blank?
			end
		end
		
		@addressee = params[:addressee].capitalize
		(@addressee = params[:workgroup] + " " + @addressee) if @addressee == "Workgroup"
		@subject = params[:subject]
		subject = "To " + @addressee + ": " + @subject
		@user = user
		@body = params[:body]
		mail(:from => "help@diem25.org", :reply_to => user.email_with_name, :to => target, :subject => subject)
	end
	
	######################
	#  CURRENTLY UNUSED  #
	######################
	def invitation_to_vote(user, vote)
    @user = user
    @vote  = vote
    mail(:to => user.email_with_name, :subject => I18n.t('voting.invitation_to_vote_title', name: user.name))
  end
  
  def after_import_email(user, password, token)
    @user = user
    @password = password
    @link  = user_confirmation_url(confirmation_token: token)
		@head_image = "https://diem25.org/wp-content/uploads/2017/08/demo_for_mail.jpg"
    mail(:to => user.email_with_name, :subject => I18n.t('verify.urgent_action_title', name: user.name))
  end
	
private
  # turns "It's your choice" into "Judith, it's your choice"
	def try_add_name(str, user)
	  if user and user.personal_name
		  str = user.personal_name + ", " + str[0,1].downcase + str[1..-1]
		end
		str
	end
	

end
