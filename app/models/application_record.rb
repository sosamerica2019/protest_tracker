class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
	
	def self.by_date(s)
    where("date_trunc('day', created_at) = ?", Date.parse(s))
  end
	
	def fix_email_format
	  self.email = email.downcase if email
	end
end