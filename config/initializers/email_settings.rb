ActionMailer::Base.smtp_settings = {
  user_name: 'SMTP_Injection',
  password: ENV['sparkpost_password'],
  address: 'smtp.eu.sparkpostmail.com',
  port: 587,
  enable_starttls_auto: true,
	#authentication: :login,
  format: :html,
  from: 'help@diem25.org'
}

Gibbon::Request.api_key = ENV['mailchimp_key']

# store list of disposable emails
TEMP_DOMAINS = File.readlines(Rails.root.join('config/disposable_emails.txt')).map{ |line| line.strip }