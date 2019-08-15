module LinksHelper

  def email(address)
	  (raw "<a href='mailto:" + address + "'>" + address + "</a>") if address
	end
	
	def url(address)
	  if address
      if address.include?("http") # outside Members Area
        raw(link_to address, address, target: "_blank")
      else
        raw(link_to address, address)
      end
    end
	end
	
	def link_out(title, url)
	  unless url.blank?
		  url = "https://" + url unless url.include?("http")
		  link_to title, url, target: "_blank"
		else
		  ""
		end
	end
	
	def op_url
    "https://diem25.org/organising-principles/"
  end
  
	def linkup_email(text)
	  raw text.gsub(/([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})/i, '<a href="mailto:\1">\1</a>')
	end
	
	def linkup_all(text)
	  text.gsub!(/([A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})/i, '<a href="mailto:\1">\1</a>')
		raw text.gsub(URI.regexp, '<a href="\0">\0</a>').html_safe
	end
	
	def link_aws_objects(objects, joiner = ", ")
		arr = []
		objects.each do |obj|
		  m = obj.key.match(/([^\/]+\z)/)
			if m and m[1]  # has match
			  filename = m[1] 
			else
			  filename = obj.key
			end
		  arr << link_to(filename, obj.public_url, target: "_blank")
		end
		raw arr.join(joiner)
	end
	
	def n(text)
	  num =   text.is_a?(String) ? text.to_i : text
		number_with_delimiter(num)
	end
end
