# encoding: UTF-8

class Array
  
  # difference between two arrays
  def ^(other)
    result = dup
    other.each{|e| result.include?(e) ? result.delete(e) : result.push(e) }
    result
  end unless method_defined?(:^)
  alias diff ^ unless method_defined?(:diff)
	
	# get only ids of complex objects in array, e.g. for manipulated ActiveRecord results
	def ids
	  self.map(&:id)
	end
	
	def include_any?(arr)
	  not (self & arr).empty?
	end
	
	# each line from a file will be one entry in the array
	def self.from_file(filename)
	  arr = []
		File.open(filename, 'r:utf-8') do |f|
		  arr = f.read.split(/[\r\n]+/u)
		end
		arr
	end
  
end