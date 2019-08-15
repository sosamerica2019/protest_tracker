class UserPrivilege < ApplicationRecord
	
	belongs_to :user
	
	#validates_inclusion_of :privilege, :in => UserPrivilege.list
	validates_presence_of :user_id

  # complete list of available privileges
  def self.list
	  [
		# Social media
		"see_all_referrals",
		
		# DSCs
		"administer_dsc_list", "administer_dscs_in_country",
		
		# Meeting summaries
		"administer_all_meeting_summaries", "administer_meeting_summaries_for_group",
		
		# Moderation
		"moderate_events", "moderate_member_presentations", "moderate_forum",
		
		# Petitions
		"administer_petitions",
		
		# Fundraisers
		"create_edit_fundraisers", "delete_fundraisers",
		
		# Votes
	  "administer_all_votes", "see_ongoing_vote", 
		
		# Elections
		"administer_all_elections",
		
		# Translations
		"translate",
		
		# Finances
		"administer_all_donations", "see_all_donations", "see_donations_for_earmark", "see_financial_overview",
		
		# Statistics - this is also automatically given to everyone who has any privilege at all
		"view_statistics",
		
		# VC manager
		"administer_vc_votes", "view_vc_applicants",
		
		# User data
	  "administer_all_users", "administer_volunteers", "administer_volunteers_in_country", "administer_users_in_country", "help_single_user",
		
		# Admins
		"assign_privileges"
		]
	end
	
	def self.superceded_privilege(privilege)
	  case privilege
		when "administer_dscs_in_country" then "administer_dsc_list"
    when "administer_meeting_summaries_for_group" then "administer_all_meeting_summaries"
    when "see_donations_for_earmark" then "see_all_donations"
		when "see_all_donations" then "administer_all_donations"
		when "administer_volunteers_in_country" then "administer_volunteers"
		when "administer_users_in_country" then "administer_all_users"
		when "administer_vc_votes" then "administer_all_votes"
		else nil
		end
	end
	
	def self.scoped_list
	  ["administer_dscs_in_country", "administer_meeting_summaries_for_group", "see_donations_for_earmark", "administer_volunteers_in_country", "administer_users_in_country"]
	end
	
	def self.assign(user, privilege, scope = nil)
		scope = user.country if scope.nil? and (privilege == "administer_users_in_country" or privilege == "administer_volunteers_in_country" or privilege == "administer_dscs_in_country")
		if user.privileges.include?([privilege, scope])
		  true
		else
	    UserPrivilege.create(user_id: user.id, privilege: privilege, scope: scope)
		end
	end
	
	def self.quick_assign(user, role)
	  case role
	  when "vc"
		  UserPrivilege.assign(user, "administer_vc_votes")
			UserPrivilege.assign(user, "view_vc_applicants")
			UserPrivilege.assign(user, "moderate_forum")
		when "country_it" # for the main person doing IT, not everyone
		  UserPrivilege.assign(user, "administer_users_in_country")
			UserPrivilege.assign(user, "administer_volunteers_in_country")
			UserPrivilege.assign(user, "administer_dscs_in_country")
			UserPrivilege.assign(user, "administer_all_meeting_summaries")  # need to eventually narrow it down to that NC
			UserPrivilege.assign(user, "translate")
			UserPrivilege.assign(user, "see_financial_overview")
			UserPrivilege.assign(user, "see_all_referrals")
			UserPrivilege.assign(user, "moderate_forum")
		when "moderator"
		  UserPrivilege.assign(user, "moderate_member_presentations")
		  UserPrivilege.assign(user, "moderate_events")	
			UserPrivilege.assign(user, "moderate_forum")
		when "low"
		  UserPrivilege.assign(user, "administer_dscs_in_country")
			UserPrivilege.assign(user, "administer_all_meeting_summaries")  # need to eventually narrow it down to that NC
		when "all"
		  (UserPrivilege.list - UserPrivilege.scoped_list - ["assign_privileges"]).each do |priv|
			  UserPrivilege.assign(user, priv)
			end
	  end
	end
	
	def self.get_scope_of_privilege(user, privilege)
	  if not UserPrivilege.list.include?(privilege)
		  raise "The privilege #{privilege} does not exist. Maybe you misspelled it? See the complete list in the UserPrivilege module."
		end
	  scope = UserPrivilege.where(user_id: user.id).where(privilege: privilege).pluck(:scope)
		if scope.nil? or scope.empty?  # maybe this is a higher admin, with unscoped access
		  list = user.privileges
			if list.flatten.include?(privilege) or (superpriv = UserPrivilege.superceded_privilege(privilege) and (not superpriv.nil?) and list.include?([superpriv, nil]))  #or user.is_superadmin?
			  scope = "any"
			end
		end
		scope
	end
	
	def self.has_privilege?(user, privilege, scope = nil)
	  if not UserPrivilege.list.include?(privilege)
		  raise "The privilege #{privilege} does not exist. Maybe you misspelled it? See the complete list in the UserPrivilege module."
		end
		list = user.privileges
		if scope.nil? or scope == 'any' and list.flatten.include?(privilege)  # if the scope is nil or 'any', this checks for e.g. whether someone is a country admin, without checking whether the country matches
		  true
		elsif scope and scope != 'any' and list.include?([privilege, scope])   # if the scope is given, this checks e.g. whether the country matches
		  true
		elsif not list.empty? and privilege == "view_statistics"
		  # give this to all admins as a boon
			true
		elsif superpriv = UserPrivilege.superceded_privilege(privilege) and (not superpriv.nil?) and list.include?([superpriv, nil])
		  # these are the non-scoped privileges that supercede the scoped ones
			true
		elsif user.is_superadmin?
		  true
		end
	end
	
	def self.remove_privilege(user, privilege, scope = nil)
	  UserPrivilege.where(user_id: user.id, privilege: privilege, scope: scope).first.delete
	end
	
	def self.remove_all_privileges(user)
	  UserPrivilege.where(user_id: user.id).delete_all
	end
	
		
end
