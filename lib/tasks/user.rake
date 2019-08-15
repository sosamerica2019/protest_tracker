namespace :user do
  task :resend_confirmation => :environment do
    users = User.where('verification_state = 0').where("created_at > ?", Time.now - 72.hours).where("created_at < ?", Time.now - 48.hours)
    users.each do |user|
      user.send_confirmation_instructions
    end
  end
end