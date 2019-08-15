ActiveAdmin.register User, as: "Admin" do

  controller do
	  before_action -> { require_privilege("assign_privileges") }
		
    def scoped_collection
			User.admins
    end
  end

  filter :privileges_privilege_eq, label: "Privilege", as: :select, collection: UserPrivilege.list
  filter :country, as: :select, collection: ISO3166::Country.translations('EN').invert
	filter :language, label: "Newsletter language", as: :select, collection: %w[English Français Deutsch Italiano Español Português Ελληνικά]
  filter :email
  filter :personal_name
	filter :family_name
	filter :created_at 

  #config.batch_actions = false
	
	batch_action :remove_all_privileges do |ids|
		batch_action_collection.find(ids).each do |user|
		  UserPrivilege.remove_all_privileges(user)
    end
    redirect_to collection_path, alert: "The selected users have been removed as admins."
  end
  
  batch_action :remove_privilege, form: {
    privilege: UserPrivilege.list
  } do |ids, inputs|
    # inputs is a hash of all the form fields you requested do |ids|
		batch_action_collection.find(ids).each do |user|
		  UserPrivilege.remove_privilege(user, inputs['privilege'])
    end
    redirect_to collection_path, alert: "The selected users have lost the privilege to #{inputs['privilege']}."
  end
	
	batch_action :add_privilege, form: {
    privilege: UserPrivilege.list
  } do |ids, inputs|
    # inputs is a hash of all the form fields you requested do |ids|
		batch_action_collection.find(ids).each do |user|
		  UserPrivilege.add_privilege(user, inputs['privilege'])
    end
    redirect_to collection_path, alert: "The selected users have gained the privilege to #{inputs['privilege']}."
  end
	
	batch_action :destroy, false
	

	action_item :dashboard do
	  link_to "Back to dashboard", root_path
	end

  index do
		selectable_column
		column "Name", sortable: :family_name do |user|
		  s = raw(verification_state_icon(user))
			s += raw("&#9993;") if not user.member? 
 			s += user.name
		end
    column :email
		column :location
	  column "Abilities" do |user|
			raw(pretty_privileges(user))
	  end
		column :created_at
		actions defaults: false do |user|
      item "Edit", admin_show_member_path(user)
    end
  end

end
