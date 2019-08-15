# Encoding: UTF-8
module HtmlHelper
  include StatsHelper

  def extra_format(text, collapse_header = t("buttons.read_more"))
	  if pos = text.index("[Expand]") and pos2 = text.index("[/Expand]")
		  text_before = text[0..pos-1]
			text_after = text[pos2+9..-1]
			inner_text = text[pos+8..pos2-1]
      s = '<div class="panel panel-default">'
      s += '<div class="panel-heading collapser mini" data-target="#custom_collapse">'
      s += '<h4>' + collapse_header + '</h4>'
      s += '</div>'
      s += '<div id="custom_collapse" class="collapse">'
      s += '<div class="panel-body">'
      s += inner_text
		  s += '</div></div></div>'
		  text = text_before + s + text_after
		end
		text
  end
	
  def gender_display(gender)
    case gender
    when "male"
      "♂"
    when "female"
      "♀"
    when "other"
      "○"
    end 
  end
 
  def i18n_str(str)
    if str
      ("'" + escape_javascript(str) + "'").html_safe  
    else
      ""
    end
	end
	
	def iframe(href, size = "normal")
	  if size == "normal"
	    '<iframe width="560" height="315" src="' + href + '" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>'
		elsif size == "small"
		  '<iframe width="200" height="176" src="' + href + '" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>'
		end
	end
	
	def pic_or_video(url, size = "normal")
	  if url.include?("<br>")  # split
		  small, normal = url.split("<br>")
			url =  (size == "normal" ? normal : small )
		end
	
	  if url.include?("youtube") or url.include?("youtu.be") or url.include?("vimeo")
		  lazy_load_video(url, size)
		elsif url.starts_with?("http") and url.length > 10  # assume picture
		  if size == "normal"
			  image_tag(url, style: "max-height: 315px; max-width: 560px;")
			elsif size == "small"
			  image_tag(url, style: "max-height: 176px; max-width: 200px;")
			end
		else
		  nil
		end
	end
	
	def transliterate(str)
	  if I18n.locale != :el
		  str.to_greeklish
		else
		  str
		end
	end
	
	def text_results(results)
	  s = ""
		if results.is_a?(Hash)  # This election has posts
		  # replace post ids with the title of that post in the current language
		  # keep "total" as-is
		  results = results.transform_keys { |key|  (key.is_a?(Integer) ? ElectionPost.find(key).area_name : key) }
		  # we still have candidate uids instead of candidate names, but we'll fix that while generating the HTML
		  total = results.delete("total")
		  results.delete_if { |k,v| v == [] }  # post that nobody applied to
		  results.each do |post_name, candidates_arr|
		    s += "<h4>#{post_name}</h4>"
			  candidates_arr.each do |candidate_uid, votes|
			    candidate = User.find(candidate_uid)
				  begin
			      s += "<p>" + transliterate(candidate.name) + " " + gender_display(candidate.gender)
				    s += " <a href='#' data-toggle='modal' data-target='#candidate#{candidate_uid}'><small>" + I18n.t('buttons.view') + "</small></a>"
				    s += " - " + number_with_percentage(votes, total) + "</p>" 
				  rescue
				    s += "<p>Problem displaying a candidate. Please add manually. Member ID #{candidate_uid}"
					  s += " - " + number_with_percentage(votes, total) + "</p>" 
				  end
			  end
			  s += "<p>&nbsp;</p>" # full empty line between different posts
		  end
		else
		  # election without posts, results is a simple array like [[2, 1], ["total_candidates_picked", 1], ["should be same total", 1], ["total", 1]]
			t = results.detect{ |s| s[0] == "total"}
			total = t[1]  if t
			total = 1 if total.nil? or total == 0  # avoid division by zero if no votes cast
			results.each do |line|
			  candidate_uid, votes = line
				if candidate_uid.is_a?(Integer)  # otherwise this is "total" or similar
				  candidate = User.find(candidate_uid)
				  begin
			      s += "<p>" + transliterate(candidate.name) + " " + gender_display(candidate.gender)
				    s += " <a href='#' data-toggle='modal' data-target='#candidate#{candidate_uid}'><small>" + I18n.t('buttons.view') + "</small></a>"
				    s += " - " + number_with_percentage(votes, total) + "</p>" 
				  rescue
				    s += "<p>Problem displaying a candidate. Please add manually. Member ID #{candidate_uid}"
					  s += " - " + number_with_percentage(votes, total) + "</p>" 
				  end
			  end
		  end
		end
		s.html_safe
	end
end
