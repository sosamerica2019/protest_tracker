module ValueNormalizer
  extend ActiveSupport::Concern

  included do
    before_save :nilify_blanks, :downcase_email
  end

  def nilify_blanks
    attributes.each do |column, value|
      self[column] = nil if self[column].is_a?(String) && self[column].empty?
    end
  end
	
	def downcase_email
	  attributes.each do |column, value|
	    self[column] = value.downcase if column.include?("email") and value
		end
	end

end