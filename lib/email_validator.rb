class EmailValidator < ActiveModel::Validator
  def validate(record)
    options[:fields].each do |field|
      email = record.send(field)
			
			if email.blank?
			  record.errors.add(field, 'cannot be empty or nil')
		  end
      m = email.match(/^[A-Z0-9._%+-]+(@[A-Z0-9.-]+\.[A-Z]{2,})$/i) if email
      if !m.nil? and m[1]
        if TEMP_DOMAINS.include?(m[1])
          record.errors.add(field, 'cannot be a temporary email')
				elsif email.include_any?([".shop", ".store", ".club", "searchengine", "jewelry", "opbeingop"])
				  record.errors.add(field, 'looks fake')
        else 
          # passed validation
        end
      else
        record.errors.add(field, 'is not a valid email')
      end
    end
  end
end