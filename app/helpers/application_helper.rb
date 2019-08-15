module ApplicationHelper

  def internal_alert(string_i18n_ref, link = nil)
	  s = "<div class=\"internal-alert\">"
		if link
		  s += "<p>" + string_with_link(t(string_i18n_ref), link) + "</p>"
		else
		  s += "<p>" + t(string_i18n_ref) + "</p>"
		end
		s += "<a href='#' class='close--alert'></a></div>"
		raw s
	end
  
  def mobile?
    agent = request.user_agent
    agent =~ /(tablet|ipad)|(android(?!.*mobile))/i or agent =~ /Mobile/
  end
	
	#def paginate(collection, params= {})
    #will_paginate collection, params.merge(:renderer => RemoteLinkPaginationHelper::LinkRenderer)
  #end
  
  # Converts
  # "string with __link__ in the middle." to
  # "string with #{link_to('link', link_url, link_options)} in the middle."
  def string_with_link(str, link_url, link_options = {})
    match = str.match(/__([^_]{2,50})__/)
    if !match.blank?
      link_options[:target] = "_blank" if link_url.include?("http")
      raw($` + link_to($1, link_url, link_options) + $')
    else
      # raise "string_with_link: No place for __link__ given in #{str}" if Rails.env.test?
      str
    end
  end
	
	# Alternative to string_with_link for pure text emails
	def string_without_link(str, link_url, link_options = {})
    match = str.match(/__([^_]{2,50})__/)
    if !match.blank?
      link_options[:target] = "_blank" if link_url.include?("http")
      raw($` + $1 + " (" + link_url + ") " + $')
    else
      # raise "string_with_link: No place for __link__ given in #{str}" if Rails.env.test?
      str
    end
  end
  
  def maybe_active_nav_li_to(title, link, options = {})
	  class_name = current_page?(link) ? 'active-internal--link' : ''
		content_tag("li", :class => class_name) do
			link_to title, link, options
		end
  end
  
  # additional i18n switcher links in the form of flags
  def flag_links_for_langs(available_langs)
    s = ""
    available_langs.each do |lang|
      lang_name = LANGUAGE_NAME[lang.to_sym]
      country = country_from_locale(lang)
      s += link_to image_tag("transparent.png", class: "flag flag-#{country}"), locale: lang, title: ("In " + lang_name)
    end
    raw s
  end
  
  def country_from_locale(langcode)
    case langcode
    when "en"
      "gb"
    when "el"
      "gr"
    when "da"
      "dk"
    else
      langcode
    end
  end
  
  def diem_ascii_symbol
    raw("<span style='color:red'>>></span>")
  end

	
	def resource_name
    :user
  end

  def resource
    @user ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
end
