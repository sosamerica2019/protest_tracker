class MyDeviseMailerPreview < ActionMailer::Preview

  def confirmation_instructions
    MyDeviseMailer.confirmation_instructions(User.first, "faketoken", {})
  end
  
  def newsletter_instructions
    u = User.first
    u.newsletter = 'Non-member' 
    MyDeviseMailer.confirmation_instructions(User.first, "faketoken", {})
  end
  
  def petition_confirmation_instructions
    u = User.where("refer LIKE 'petition%'").sample
		if u.nil?
		  u = User.newsletter_subscriber.first
			u.refer = 'petition' + Petition.first.id.to_s
			u.save
		end
    MyDeviseMailer.confirmation_instructions(u, "faketoken", {})
  end

  def reset_password_instructions
    MyDeviseMailer.reset_password_instructions(User.first, "faketoken", {})
  end
end