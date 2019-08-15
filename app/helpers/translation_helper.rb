module TranslationHelper

  def t_array(arr, context)
	  result = []
	  context = context + "." unless context.ends_with?(".")
		arr.each do |item|
		  result << t(context + item.downcase.gsub(/\W/, '_'))
		end
		result
	end
	
	def t_for_select(arr, context)
	  t_array(arr, context).zip(arr)
	end
end
