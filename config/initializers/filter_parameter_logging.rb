# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password, :password_confirmation]

# Personal data
Rails.application.config.filter_parameters += [:email, :personal_name, :family_name, :address, :mobile]

# Chosen vote options
Rails.application.config.filter_parameters += [:voted_option]
(1..20).each do |i|
  Rails.application.config.filter_parameters += ["voted_candidate#{i}".to_sym, "options_#{i}".to_sym]
end

