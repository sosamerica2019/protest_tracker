class Event < ApplicationRecord

  belongs_to :user
	
	before_save :set_for_online_event
	
	validates_presence_of :user_id, :title, :description, :organizer_name, :location_name, :travel_distance, :event_start, :event_type, :audience, :rsvp_address
	validates :location_country, length: { is: 2 }, allow_blank: true
	validates :title, length: { maximum: 100 }
	validates :location_name, length: { maximum: 50 }
	validates_inclusion_of :event_type, :in => %w(home demonstration meal picknick party lecture debate flashmob workshop movie book_presentation internal work_meeting volunteering outdoors)
	validates_inclusion_of :audience, :in => %w(i d j p)
	validates_inclusion_of :moderation, :in => %w(u s a r)
	validates :picture_url, format: { with: /amazonaws.com.+(\.|\/)(gif|jpe?g|png|svg)\z/i,
    message: "upload did not succeed or the file was in an unsupported format" }, allow_blank: true
  validate :end_date_is_after_start_date
	
	scope :to_moderate, -> { where(moderation: ['s', 'u']) }
	scope :approved, -> { where("moderation = 'a'") }
	scope :rejected, -> { where("moderation = 'r'") }
	scope :to_show, -> { where("moderation != 's' AND moderation != 'r'") }
	scope :by_importance, -> { order("event_start ASC, travel_distance DESC, location_size DESC") }
	
	attr_accessor :end_nil  # event without end
	
	def audience_type
	  I18n.t("events.audience." + self.audience, locale: :en)
	end
	
	def self.between_dates(from, to)
	  from = Time.parse(from)  unless from.is_a?(Time)
		to = Time.parse(to) + 24.hours unless to.is_a?(Time)
		where("event_start >= ?", from).where("event_start < ? or event_end < ?", to, to)
	end
	
	def self.between_times(from, to)
		where("event_start >= ?", from).where("event_start < ? or event_end < ?", to, to)
	end
	
	def location_mini
	  s = ""
		unless self.online?
		  (s += self.location_city + ", ") unless self.location_city.blank?
			(s += self.location_country_name) unless self.location_country.blank?
		end
		s
	end
	
	def location_minimini
	  if self.online?
		  "Online"
		elsif !self.location_city.blank?
		  self.location_city
		else
		  self.location_country_name
		end
	end
	
	def location_country_name
	  unless self.location_country.blank?
      country_data = ISO3166::Country[self.location_country]
			if country_data
			  (country_data.translations[I18n.locale.to_s] || country_data.name)
			else
			  ""
			end
    else
      ""
    end
	end
	
	def lasting_days
	  if self.event_end.blank?
		  1
		else
		  (self.event_end.to_date - self.event_start.to_date).days.to_i
		end
	end
	
	def distance_from(point)
	  Geo.distance(self.location_geo, point)
	end
	
	def end_time
    self.event_end
  end
	
	def is_important?
	  self.travel_distance > 200 and self.travel_distance < 40000
	end
	
	def moderation_state
	  case self.moderation
		when "u" then "unmoderated"
		when "s" then "suspicious"
		when "a" then "approved"
		when "r" then "rejected"
		end
	end
	
	def multiday?
	  self.event_end and self.event_end.to_date != self.event_start.to_date
	end
	
	def online?
	  self.travel_distance == 40000
	end
	
	def own_or_admin?(user)
	  user.is_admin? or self.user_id == user.id
	end
	
	def rsvp
	  if rsvp_address.include?('@')
		  "mailto:" + rsvp_address
		else
		  rsvp_address
		end
	end
	
	def shown?
	  moderation != 'r' and moderation != 's'
	end
	
	def start_time
    self.event_start
  end
	
	def time
	  self.event_start.strftime("%H:%M")
	end
	
	# takes an array of events and duplicates those that last longer than a day
	def self.unpack_multiday(events)
	  new_events = []
		events.each do |event|
		  new_events << event
		  if event.multiday?
			  day = event.event_start.to_date.to_time  # midnight on start day
			  begin
			    day = day + 1.day
					event2 = event.dup
				  event2.event_start = day  # midnight next day
					event2.id = event.id
				  new_events << event2
				end until (day + 1.day) > event.event_end
			end
		end
		new_events
	end
	
#######
private
#######

def end_date_is_after_start_date
  return true  if event_end.blank? || event_start.blank?

  if event_end < event_start
    errors.add(:event_end, "cannot be before the event start") 
  end 
end

# before save
def set_for_online_event
  if self.online?
	  self.location_name = 'Online'
		self.location_city = nil
		self.location_country = nil
		self.location_geo = nil
	end
	if self.end_nil == '1'
	  self.event_end = nil
	end
end
	
end
