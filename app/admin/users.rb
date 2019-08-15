ActiveAdmin.register User do
# See permitted parameters documentation:
# https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
#
# permit_params :list, :of, :attributes, :on, :model
#
# or
#
# permit_params do
#   permitted = [:permitted, :attributes]
#   permitted << :other if params[:action] == 'create' && current_user.admin?
#   permitted
# end

   controller do
	   before_action -> { require_privilege("administer_users_in_country", "any") }
		 
    def scoped_collection
		  scope = UserPrivilege.get_scope_of_privilege(current_user, "administer_users_in_country")
			if scope != "any"
        User.where(country: scope)
			else
			  User
			end
    end
  end

  filter :country, as: :select, collection: ISO3166::Country.translations('EN').invert, if: proc {current_user.has_privilege?("administer_all_users") }
	filter :postal_code
	filter :city
	filter :language, label: "Newsletter language", as: :select, collection: %w[English Français Deutsch Italiano Español Português Ελληνικά]
  filter :email
  filter :personal_name
	filter :family_name
	filter :birthdate
	filter :created_at 
	filter :volunteer_abilities_contains, as: :select, collection: VOLUNTEER_ABILITIES
	filter :volunteer_abilities_desc
	filter :which_local, label: "Wants local collective in", as: :select, collection: User.where("which_local IS NOT NULL").distinct.pluck(:which_local).sort
	filter :which_thematic, as: :select, collection: ["European New Deal", "Transparency", "Refugees & Migration", "Constitution", "Tech", "Labour", "Green Transition", "national policies", "other"], label: "Wants thematic collective about"
	filter :mera25_present, as: :boolean, label: "MeRA25 member"
	filter :district, label: "Electoral district (MeRA25)"

  batch_action :destroy, if: proc{ current_user.has_privilege?('administer_all_users') }
	
	action_item :import do 
		link_to "Import members", import_members_path
	end
	action_item :dashboard do
	  link_to "Back to dashboard", root_path
	end

  index do
		selectable_column
		column "First name", sortable: :personal_name do |user|
		  s = raw(verification_state_icon(user))
			s += raw("&#9993;") if not user.member? 
 			s += user.personal_name
		end
		column :family_name
    column :email
		if params['q'] and params['q']['volunteer_abilities_contains']
		  column :location
			column "Volunteer" do |user|
			  raw(user.volunteer_hours_per_week.to_s + " hours/week<br>" + user.volunteer_abilities.to_s.gsub("_", " "))
			end
			column "Description", :volunteer_abilities_desc
    elsif params['q'] and params['q']['mera25_present'] == 'true'
		  column :voting_district 
			column "Want AO in", :which_local
			column :which_thematic
		else
		  column :location, sortable: :city
    end
		column :created_at
		actions defaults: false do |user|
      item "Show", admin_show_member_path(user) if current_user.has_privilege?('administer_users_in_country')
			item "Edit", admin_edit_member_path(user) if current_user.has_privilege?('administer_users_in_country')
    end
  end

end
