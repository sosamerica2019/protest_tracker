# encoding: UTF-8

class String
  
  # no parenthesis, spaces or other funny characters
  # format like +4915153721439
  def standardise_phone_number
    s = self.gsub("(0)", '') # remove national prefix not used internationally
    s = self.gsub(/[^0-9\+]*/, '')
    s = "+" + s[2..-1] if s[0,2] == "00"
    s
  end
	
	def to_greeklish
		greek = "αβγδεζηικλμνοπρστυφωξάέήίόύώςΑΒΓΔΕΖΗΙΚΛΜΝΟΠΡΣΤΥΦXΩΞΆΈΉΊΌΎΏ"
		greeklish = "avgdeziiklmnoprstyfxoáéííóyósAVGDEZIIKLMNOPRSTYFXWÁÉÍÍÓÚÓ"
		s = self.tr(greek, greeklish)
		if s != self  # this is Greek
		  s = s.gsub("θ", "th").gsub("χ", "ch").gsub("ψ", "ps").gsub("Θ", "Th").gsub("X", "Ch").gsub("Ψ", "Ps").gsub("oy", "ou").gsub("Oy", "Ou").gsub("ay", "av").gsub("ey", "ev").gsub("Ay", "Av").gsub("Ey", "Ev").gsub("gg", "ng")
		end
		s
	end
	
	def with_https
	  if self.starts_with?("http")
		  self
		elsif self.starts_with?("//")
		  "https:" + self
		end
	end
  
  
  # find if this string includes any of the strings from the array (case insensitive)
  def find_one_word_from(arr)
    test_str = " " + self + " "
	  arr.each do |str|
	    return str if test_str.include?(" " + str.downcase + " ")
	  end
	  nil
  end
	
	# check if string includes any members of the array
	def include_any?(arr)
	  arr.any? { |str| self.include?(str) }
	end
	
	def is_Numeric?
	  self.to_i.to_s == self
	end
  
  def remove_css_styles!(*styles)
    s = self
    styles.each do |style|
      s.gsub!(/#{style}[^;]+; ?/, '')
    end
    s.gsub!(' style=""', '')
    s
  end
  
end