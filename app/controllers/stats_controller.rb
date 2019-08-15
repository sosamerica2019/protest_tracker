class StatsController < ApplicationController
  before_action -> { require_privilege("view_statistics") }, except: [:share_update, :my_signups, :signups_for_external, :top_referrers]
	before_action :authenticate_user!, only: [:my_signups]
	before_action :set_timeframe, except: [:share_update, :my_signups]
	
	include StatsHelper
	require 'csv'

	
	def signups_for_external
	  @data = nil
	  if params["u"] == 'sInu9yu12df'
		  if params["segment"] == 'GR'
		    @data = User.where("country = 'GR' OR language = '" + CORE_LANGUAGE_NAME[:el] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count	
		  elsif params["segment"] == 'ES'
		    @data = User.where("country = 'ES' OR language = '" + CORE_LANGUAGE_NAME[:es] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count
		  elsif params["segment"] == 'DE'
		    @data = User.where("country = 'DE' OR language = '" + CORE_LANGUAGE_NAME[:de] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count
      elsif params["segment"] == 'FR'
		    @data = User.where("country = 'FR' OR language = '" + CORE_LANGUAGE_NAME[:fr] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count
      elsif params["segment"] == 'IT'
		    @data = User.where("country = 'IT' OR language = '" + CORE_LANGUAGE_NAME[:it] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count
      elsif params["segment"] == 'PT'
		    @data = User.where("country = 'PT' OR language = '" + CORE_LANGUAGE_NAME[:pt] + "'").where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count	
		  else
		    @data = User.where("created_at > ?", Time.now - 2.months).group_by_day(:created_at).count
		  end
			attributes = ["Date","Signups"]
		
		  t = CSV.generate(headers: true) do |csv|
		    csv << attributes
			  @data.each do |k, v|
			    csv << [k.strftime("%Y%m%d"), v]
			  end
		  end
			
			respond_to do |format|
		    format.csv { render csv: t }
		  end
		end
	end
	
	def top_referrers
	  @data = nil
		if params["u"] == 'sInu9yu12df'
		  if params["segment"] == 'GR'
		    @data = User.where("country = 'GR' OR language = '" + CORE_LANGUAGE_NAME[:el] + "'")
		  elsif params["segment"] == 'ES'
		    @data = User.where("country = 'ES' OR language = '" + CORE_LANGUAGE_NAME[:es] + "'")
		  elsif params["segment"] == 'DE'
		    @data = User.where("country = 'DE' OR language = '" + CORE_LANGUAGE_NAME[:de] + "'")
      elsif params["segment"] == 'FR'
		    @data = User.where("country = 'FR' OR language = '" + CORE_LANGUAGE_NAME[:fr] + "'")	
      elsif params["segment"] == 'IT'
		    @data = User.where("country = 'IT' OR language = '" + CORE_LANGUAGE_NAME[:it] + "'")
      elsif params["segment"] == 'PT'
		    @data = User.where("country = 'PT' OR language = '" + CORE_LANGUAGE_NAME[:pt] + "'")
		  else
		    @data = User
		  end
			@data = @data.where("refer IS NOT NULL AND refer != ''").where("created_at > ?", Time.now - 1.month).group(:refer).order("count_all DESC").count
		
		  count_refer = 0
		  attributes = ["Name","Signups"]
		  t = CSV.generate(headers: true) do |csv|
		    csv << attributes
			  @data.each do |referrer|
			    if count_refer < 10
				    name = referrer[0]
					  if name.starts_with?("u")
					    name = User.find(name[1..-1].to_i).name
					  end
			      csv << [name, referrer[1]]
					  count_refer += 1
				  end
			  end
		  end
		  respond_to do |format|
		    format.csv { render csv: t }
		  end
		end
	end
	
	def members
	  #require 'StatsHelper'
		@activation_stats = {}
		@activation_stats["header"] = ["lang", "total", "newsletter", "member-0", "member-basic", "verified", "active 3 months", "ver+active", "voted in last"]
		@last_vote = []
		total_votes = VoteRecord.where(vote_id: Vote.open_to_all.last.id).count
		
		["en", "de", "el", "es", "it", "fr", "pt"].each do |lang|
		  m = User.by_lang(lang)
			total = m.count
			total_m = m.member.count
			veractive = m.member.verified.where("current_sign_in_at > ?", Time.now - 3.months).count
			lastvote = VoteRecord.where(vote_id: Vote.open_to_all.last.id).where(user_id: m.member.verified).count
		  @activation_stats[lang] = [
			  total, 
				number_with_percentage(m.newsletter_subscriber.count, total),
				number_with_percentage(m.member.where(verification_state: 0).count, total_m),
				number_with_percentage(m.member.where(verification_state: 1).count, total_m),
				number_with_percentage(m.member.verified.count, total_m), 
				number_with_percentage(m.member.where("current_sign_in_at > ?", Time.now - 3.months).count, total_m),
				veractive,
				number_with_percentage(lastvote, veractive)
			]
			@last_vote += [percentage(lastvote, total_votes) + " " + LANGUAGE_NAME[lang.to_sym]]
		end		
	end
	
	def members_by_country
	  @countries = User.group(:country).order("count_all DESC").count
		@countries_for_diagram = {"other" => 0}
		@countries.each do |country, amount|
		  if @countries_for_diagram.size <= 11
			  # list 10 biggest countries
				if country.nil?
				  country = "unknown"
				else
				  country = ISO3166::Country[country].name if ISO3166::Country[country]
				end
			  @countries_for_diagram[country] = amount
			else
			  # the rest is 'other'
				@countries_for_diagram["other"] += amount
			end
		end
		render json: @countries_for_diagram
	end
	
	def members_by_type
	  result = {
      "Bigger fee" => User.where("membership_fee = 'supporter'").count,
      "Regular fee" => User.where("membership_fee = 'regular'").count,
			"Reduced fee" => User.where("membership_fee = 'reduced'").count,
      "Non-paying" => User.where("newsletter != 'Non-member' and (membership_fee = 'none')").count,
			"Undecided" => User.where("newsletter != 'Non-member' and (membership_fee = 'unspecified')").count,
      "Newsletter only" => User.where("newsletter = 'Non-member'").count
		}
		
		render json: result
	end
	
		
	def members_by_other
	  extra_where = "newsletter != 'Non-member'" if @attribute == :verification_state
		render json: User.where(extra_where).group(@attribute).count
	end
	
	def my_signups
		@tag_totals = User.where("refer IS NOT NULL AND refer != '' AND refer NOT LIKE 'u%'").group(:refer).order("count_all DESC").count if current_user.has_privilege?("see_all_referrals")
		if current_user.has_privilege?("see_all_referrals")
		  @referred_users = User.where("refer IS NOT NULL AND refer != ''").order("created_at DESC").limit(300)
		else
		  @my_refer = "u" + current_user.id.to_s
		  @referred_users = User.where(refer: @my_refer).order("created_at DESC")
		end
	end
	
  def signups
	end
	
	def signups_by_other	
	  extra_where = "newsletter != 'Non-member'" if @attribute == :verification_state
		if @weekly
	    render json: User.where("created_at > ? AND created_at <= ?", @from, @to).where(extra_where).
		                  group(@attribute).group_by_week(:created_at).count.chart_json
		else
	    render json: User.where("created_at > ? AND created_at <= ?", @from, @to).where(extra_where).
		                  group(@attribute).group_by_day(:created_at).count.chart_json		
		end
	end

	def signups_by_type
		if @weekly
		  result = [
        {name: "Newsletter only", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter = 'Non-member'").group_by_week(:created_at).count },
        {name: "Paying members", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("membership_fee = 'regular' OR membership_fee = 'reduced' OR membership_fee = 'supporter'").group_by_week(:created_at).count },
        {name: "Non-paying", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter != 'Non-member' and (membership_fee = 'none')").group_by_week(:created_at).count },
				{name: "Undecided", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter != 'Non-member' and (membership_fee = 'unspecified')").group_by_week(:created_at).count }	
      ]		
		else
		  result = [
        {name: "Newsletter only", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter = 'Non-member'").group_by_day(:created_at).count },
        {name: "Paying members", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("membership_fee = 'regular' OR membership_fee = 'reduced' OR membership_fee = 'supporter'").group_by_day(:created_at).count },
        {name: "Non-paying", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter != 'Non-member' and (membership_fee = 'none')").group_by_day(:created_at).count },
				{name: "Undecided", data: User.where("created_at > ? AND created_at <= ?", @from, @to).
			    where("newsletter != 'Non-member' and (membership_fee = 'unspecified')").group_by_day(:created_at).count }	
      ]
		end
		
		render json: result.chart_json
	end
	
	def voting
	end
	
	def voting_last_election
	  render json: ElectionVoteRecord.where("created_at > ? AND created_at <= ?", @from, @to).where(extra_where).
		                  group(@attribute).count.chart_json	
	end
	
	
	def share_update
	  if params[:page] and params[:reason]
		  Store.increase(params[:page] + "-" + params[:reason])
		elsif params[:page] and params[:amount]
		  Store.increase_by(params[:page], params[:amount])
		end
		render plain: "ok"
	end
	
protected

  def set_timeframe
	  @from = params[:from] || Date.today - 1.month
		@to = params[:to] || Date.today + 1.day
		@weekly = false
		@weekly = true if params[:weekly] == "true"
		if params[:attribute]
		  @attribute = params[:attribute].to_sym
		  @attribute = "invalid" unless [:gender, :language, :verification_state, :volunteer].include?(@attribute)
		else
		  @attribute = 'language'
		end
	end

end
