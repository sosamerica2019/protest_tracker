class EventsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
	before_action :set_event, only: [:show, :edit, :update, :destroy]
	before_action :set_s3_direct_post, only: [:new, :edit, :create, :update]
	before_action  -> { require_privilege("moderate_events") }, only: [:reviewer_index]

  # GET /events
  def index
	  if params[:from] 
		  @from = Time.parse(params[:from])
			params[:to] ? @to = Time.parse(params[:to]) + 24.hours : @to = @from + 60.days
		else 
		  @from = Time.now.beginning_of_month
		  @to = Time.now + 60.days
		end		
		events = Event.to_show.between_times(@from, @to).by_importance.all
		@events = Event.unpack_multiday(events)
		render layout: "external_seamless"
  end
	
	def reviewer_index
	  @events = Event.to_moderate.where("event_start > ?", Time.now - 1.month).order("id DESC").all
		@approved_events = Event.approved.where("event_start > ?", Time.now - 1.month).order("id DESC").all
		@rejected_events = Event.rejected.where("event_start > ?", Time.now - 1.month).order("id DESC").all
	end

  # GET /events/1
  def show
	  if not (@event.shown? or current_user.has_privilege?("moderate_events"))
		  redirect_to :dashboard, notice: "This event is not currently available or is in internal review."
		elsif current_user
		  render layout: "application"
		else
		  render layout: "external_seamless"
		end
  end

  # GET /events/new
  def new
    @event = Event.new
		@event.user_id = current_user.id
		@event.organizer_name = current_user.name
		@event.event_start = Time.parse((Date.today + 5.days).to_s + " 19:00")
		#@event.event_end = Time.parse((Date.today + 5.days).to_s + " 22:00")
		@event.location_city = current_user.city
		@event.location_country = current_user.country
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events
  def create
		@event = Event.new(event_params.merge(user_id: current_user.id))
		@event.event_end = nil  if params[:event][:end_nil] == '1'
		notice = I18n.t('events.created') + " " + I18n.t('contact_all.hint')
		if not current_user.is_admin? and @event.travel_distance > 160
		  @event.moderation = 's'  # unmoderated / suspicious, not shown until approved
			notice = I18n.t('events.created_pending_approval')
		elsif not current_user.is_admin?
		  @event.moderation = 'u' # unmoderated / probably fine, show without approval
		end
		
    if @event.save
			redirect_to @event, notice: notice
    else
      render :new
    end
  end

  # PATCH/PUT /events/1
  def update	
		if @event.user_id == current_user.id or current_user.has_privilege?("moderate_events")
		  old_status = @event.moderation
			@event.assign_attributes(event_params.reject{|_, v| v.blank?})
			@event.event_end = nil  if params[:event][:end_nil] == '1'
			if @event.save
			  # if this was a moderator approving the event
				puts "*" * 50
				puts "Moderation: " + @event.moderation_was
				if current_user.has_privilege?("moderate_events") and old_status != 'a' and @event.moderation == 'a'
				  UserMailer.confirmed_event(@event).deliver_later
					redirect_to review_events_path, notice: 'Event was approved and the organiser was notified.'
				else
				  redirect_to @event, notice: 'Event was successfully updated.'
				end
      else
        render :edit
      end
		else
		  flash[:alert] = "You do not have the privilege to edit other members' events."
		end
  end

  # DELETE /events/1
  def destroy
	  if @event.user_id == current_user.id or current_user.has_privilege?("moderate_events")
		  @event.destroy
      redirect_to events_url, notice: 'Event was successfully destroyed.'
		else
		  flash[:alert] = "You do not have the privilege to delete other members' events."
		end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end
		
		def set_s3_direct_post
      @s3_direct_post = S3_BUCKET.presigned_post(key: "events/#{current_user.id}/${filename}", success_action_status: '201', acl: 'public-read')
    end

    # Only allow a trusted parameter "white list" through.
    def event_params
      params.require(:event).permit(:title, :event_type, :organizer_name, :rsvp_address, :event_start, :event_end, :end_nil, :location_name, :location_address, :location_city, :location_country, :location_geo, :location_size, :travel_distance, :description, :picture_url, :details_url, :tickets_url, :audience, :moderation)
    end
end
