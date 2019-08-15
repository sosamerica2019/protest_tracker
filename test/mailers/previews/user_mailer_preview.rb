class UserMailerPreview < ActionMailer::Preview

  def after_import_email
    UserMailer.after_import_email(User.first, "progressivestogether", "a1a1a1a1")
	end

  def confirmation_email
    MyDeviseMailer.confirmation_instructions(User.first, "a1a1a1a1")
  end
	
	def donation_thanks
	  UserMailer.donation_thanks(Donation.all.sample)
	end
	
	def election_reminder
	  UserMailer.election_reminder(User.first)
	end
	
	def payment_failed
	  UserMailer.payment_failed(Donation.all.sample)
	end
	
	def payment_failed_completely
	  UserMailer.payment_failed_completely(Donation.all.sample)
	end
	
	def payment_now_okay
	  UserMailer.payment_now_okay(Donation.all.sample)
	end
	
	def petition_thanks
		sig = PetitionSignature.new(petition_id: Petition.pluck(:id).sample, personal_name: 'Judith', email: 'yutian.mei+testtest@gmail.com', wants_newsletter: 'true')
	  UserMailer.petition_thanks(sig)
	end
	
	def problematic_presentation
    UserMailer.problematic_presentation(User.first)
  end
	
	def reactivate_inactive
	  UserMailer.reactivate_inactive(User.first, "recently")
	end
	
	def remind_confirmation
	  UserMailer.remind_confirmation(User.first)
	end
	
	def vc_elected
    UserMailer.vc_elected(User.first)
  end
	
	def vc_time_ended
    UserMailer.vc_time_ended(User.first)
  end
end