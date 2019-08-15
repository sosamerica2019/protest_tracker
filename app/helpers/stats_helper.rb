module StatsHelper

  def number_with_percentage(amount, total)
	  if amount and total and total > 0 and amount > 0
		  amount.to_s + " (" + (amount.to_f / total * 100).to_i.to_s + "%)"
		else
		  amount.to_s
		end
	end
	
	def percentage(amount, total)
	  if amount and total and total > 0 and amount > 0
		  (amount.to_f / total * 100).to_i.to_s + "%"
		else
		  "0%"
		end
	end
	
	def table_from(stats)
	  s = "<table><tr>"
		stats["header"].each do |column_head|
		  s += "<th>" + column_head + "</th>"
		end
		s += "</tr>"
		stats.delete("header")
		stats.each do |key, row|
		  s += "<tr><td><b>" + key + "</b></td>"
			row.each do |value|
			  s += "<td>" + value.to_s + "</td>"
			end
			s += "</tr>"
		end
		s += "</tr></table>"
		raw(s)
	end
end
