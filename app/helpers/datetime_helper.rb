module DatetimeHelper

  def duration(from, to = nil)
	  if to.nil?
		  from.strftime("%d/%m/%Y @ %H:%M")
		elsif to.to_date == from.to_date
		  from.strftime("%d/%m/%Y @ %H:%M") + " - " + to.strftime("%H:%M")
		else  # multi-day
		  raw(" &nbsp; " + from.strftime("%d/%m/%Y @ %H:%M") + "<br> - " + to.strftime("%d/%m/%Y @ %H:%M"))
		end
	end
	
end
