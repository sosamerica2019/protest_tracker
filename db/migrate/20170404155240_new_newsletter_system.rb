class NewNewsletterSystem < ActiveRecord::Migration[4.2]
  def up
	  add_column :users, :newsletter, :string, default: "Member"
		add_column :users, :activist_newsletter, :boolean, default: false
		
		User.update_all("newsletter = 'Member'")
		User.where(newsletter_only: true).update_all("newsletter = 'Non-member'")
		
		remove_column :users, :newsletter_only
  end
	
	def down
	  add_column :users, :newsletter_only, :boolean, default: false
		
		User.where("newsletter = 'Non-member'").update_all("newsletter_only = true")
		User.where("newsletter = 'Member'").update_all("newsletter_only = false")
		
		remove_column :users, :newsletter
		remove_column :users, :activist_newsletter
	end
end
