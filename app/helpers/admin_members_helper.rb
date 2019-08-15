module AdminMembersHelper

  def verification_state_icon(user)
    case user.verification_state
		when -1
      "<i class='black-dot' title='Has not finished registration'></i>"
    when 0
      "<i class='red-dot' title='Has not confirmed their email address'></i>"
    when 1
      "<i class='yellow-dot' title='Verified email, unverified identity'></i>"
		when 2
		  "<i class='yellow-dot' title='Verified email, requesting verification'></i>"
    when 3
      "<i class='green-dot' title='Fully verified incl. phone'></i>"
		when 4
		  "<i class='green-dot' title='Fully verified incl. passport'></i>"
    end 
  end
	
	def verification_state_with_icon(user)
	  case user.verification_state
		when -1
      "<i class='black-dot'></i> -1 (Has not finished registration)"
    when 0
      "<i class='red-dot'></i> 0 (Has not confirmed their email address)"
    when 1
      "<i class='yellow-dot'></i> 1 (Verified email, unverified identity)"
		when 2
		  "<i class='yellow-dot'></i> 2 (Verified email, requesting identity verification)"
    when 3
      "<i class='green-dot'></i> 3 (Fully verified by phone)"
		when 4
		  "<i class='green-dot'></i> 4 (Fully verified by passport/ID)"
    end 
	end
	
	def verify_todos
	  num = User.where(verification_state: 2).count
		if num > 0
		  " (" + num.to_s + ")"
		else
		  ""
		end
	end
	
	def quick_state(user)
		s = verification_state_icon(user)
		s += "&#9993;" if not user.member?
		raw s
	end
	
	def name_with_location(user)
	   user.name + " (" + user.location + ") "
	end
	
	def pretty_privileges(user, joiner = ", ")
	  arr = []
		user.privileges.each do |priv, scope|
		  if scope
			  arr << (priv + " (" + scope + ") ") 
			else
			  arr << priv
			end
		end
		arr.sort.join(joiner)
	end

end
