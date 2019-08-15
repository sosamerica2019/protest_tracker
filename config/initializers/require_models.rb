# Core extensions
Dir[File.join(Rails.root, "lib", "core_ext", "*.rb")].each {|l| require l }

require File.join(Rails.root, "lib", "diem_haikunator.rb")
require File.join(Rails.root, "lib", "email_validator.rb")