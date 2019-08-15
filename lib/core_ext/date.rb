# encoding: UTF-8

class Date
  
	def self.includes_monthly_on_day(date1, date2, mday)
	  if date2.mday > date1.mday   # e.g. range May 1 to May 31
		  (date1.mday..date2.mday).include?(mday)
		else # rollover effect, e.g. range May 20 to June 5
		  (date1.mday..31).include?(mday) or (0..date2.mday).include?(mday)
		end
	end
	
	def self.includes_yearly_on_day(date1, date2, yday)
	  if date2.yday > date1.yday  # e.g. range 20 to 61
	    (date1.yday..date2.yday).include?(yday)
		else # rollover effect, e.g. range 350 to 20
		  (date1.yday..366).include?(yday) or (0..date2.yday).include?(yday)
		end
	end
	
  # number of months between two dates
  def self.months_between(date1, date2)
		(date2.year - date1.year) * 12 + date2.month - date1.month - (date2.day >= date1.day ? 0 : 1)
  end
	
	# number of years between two dates, assumes 365 days a year ignoring leap years
  def self.years_between(date1, date2)
		(date2 - date1).to_i / 365
  end
  
end