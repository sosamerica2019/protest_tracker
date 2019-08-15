namespace :import do
  desc "Check an online CSV file whether it can be imported or has deficiencies."
  task :csv_check => :environment do
	  # Make file locally available
		STDOUT.puts "What is the online URL of the .csv file?"
		file_url = STDIN.gets.chomp
		require 'open-uri'
    open('to_import.csv', 'wb') do |file|
      file << open(file_url).read
    end
		
		# Parse CSV
		@users = []
		@existing_users_count = 0
		@errors = []
		@countries = {}
		necessary_fields = %w(personal_name family_name email country language)
		h = nil
		row_count = 0
		CSV.foreach("to_import.csv", headers: true) do |row|
		  h = row.to_hash.rekey { |k| k.downcase.gsub(" ", "_") }
		
		  # convert "full name" to personal name and family name
		  if h["full_name"]
				h["personal_name"], h["family_name"] = h["full_name"].strip.split(" ", 2)  # best guess
				h.delete("full_name")
			end
		
      if row_count == 0
			  # Check if all required fields are set
		    fields = h.keys
		    missing_fields = necessary_fields - fields
				abort("The file is missing fields: " + missing_fields.join(", ")) unless missing_fields.empty?
			end
			begin 
				
				# ensure country is set correctly, convert if necessary
				cname = h["country"]
				if h["country"] and h["country"].length > 2
				  unless cname = @countries[h["country"]]
					  c = ISO3166::Country.find_country_by_name(h["country"])
					  if c.nil?
					    @errors << ("Unknown country: " + h["country"])
					  else
					    cname = c.alpha2
							@countries[h["country"]] = c.alpha2
				    end
					end
					h["country"] = cname
				end
				
				# Alert about users with invalid data
				necessary_fields.each do |field|
				  @errors << "User #{h["email"]} is missing field #{field}" if h[field].blank?
				end
				
				# Check for unknown columns
				User.new(h)  if row_count == 0  
				
			rescue ActiveRecord::UnknownAttributeError => e
			  if row_count == 0
				  @errors << "Unknown column in CSV file: " + e.attribute + ". <br>" + "Available columns are: personal_name, family_name, email, password, password_confirmation, mobile, city, country, gender, twitter, language, volunteer, postal_code, birthdate, volunteer_abilities, volunteer_abilities_desc, volunteer_hours_per_week"
			  end
			end
			row_count += 1
    end
		puts @errors.join("\n")
		puts "All checked."
  end

	desc "Import an online CSV file with 1000+ users."
  task :csv => :environment do
		
		if not File.exists?("to_import.csv")
		  STDOUT.puts "The file to import was not found. If you are certain that csv_check would succeed, you can import the file now anyway. Import it now? (yes/no)"
		  if (STDIN.gets.chomp.downcase == "yes")
			# Make file locally available
		    STDOUT.puts "What is the online URL of the .csv file?"
		    file_url = STDIN.gets.chomp
		    require 'open-uri'
        open('to_import.csv', 'wb') do |file|
          file << open(file_url).read
        end
			else
			  abort("Please run import:csv_check first.")
			end
		end 
		
		STDOUT.puts "Import these as full members? (yes/no)"
		newsletter_only = (STDIN.gets.chomp.downcase == "no")
		
		# Parse CSV
		@errors = []
		@countries = {}
		necessary_fields = %w(personal_name family_name email country language)
		h = nil
		@users_count = 0
		@existing_users_count = 0
		row_count = 0
		CSV.foreach("to_import.csv", headers: true) do |row|
		
  		h = row.to_hash.rekey { |k| k.downcase.gsub(" ", "_") }
			  
			# convert "full name" to personal name and family name
			if h["full_name"]
				h["personal_name"], h["family_name"] = h["full_name"].strip.split(" ", 2)  # best guess
				h.delete("full_name")
			end
				
			# ensure country is set correctly, convert if necessary
			cname = h["country"]
			if h["country"] and h["country"].length > 2
			  unless cname = @countries[h["country"]]
					c = ISO3166::Country.find_country_by_name(h["country"])
					if c.nil?
				    abort("Unknown country: " + h["country"])
				  else
				    cname = c.alpha2
						@countries[h["country"]] = c.alpha2
			    end
				end
				h["country"] = cname
			end
				
			h["email"].strip! # leading or trailing spaces are a common source of error
			h["city"].capitalize! if h["city"]
				
			if User.find_by_email(h["email"])
			  @existing_users_count += 1
			else
			  user = User.new(h)
			  if user.password
		      user.password_confirmation = user.password
		    else
		      user.assign_random_password!
		    end
		    user.skip_confirmation!  # no email sent to them
		    user.verification_state = 1
		    user.newsletter_only = newsletter_only
		    if user.save # or user.valid? for testing
				  @users_count += 1
		  	  Newsletter.subscribe(user)
		    else
		      puts "Member #{user.email} had invalid data and could not be added."
		    end
					
		  end
			
			row_count += 1
			puts "Now on row #{row_count}..." if (row_count % 100 == 0)
    end
		puts "#{@users_count} new users were imported, #{@existing_users_count} existing users were ignored."
  end
end