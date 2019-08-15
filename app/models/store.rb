class Store < ApplicationRecord
  # for simplicity, there are two kinds of general-purpose storage in this class
	# one is a database-based storage, the other is access methods for text-based S3 storage
	
	#---------------------------------------
	# Database Storage for system-wide config
	# treat as a Hash
	#---------------------------------------

  def self.[](key)
		Store.where(a_key: key).limit(1).pluck(:a_value).first
	end

	def self.[]=(key, value)
	  Store.where(a_key: key).first_or_initialize.update(a_value: value)
	end
	
	def self.last_change(key)
	  Store.where(a_key: key).limit(1).pluck(:updated_at).first
	end
	
	# equivalent of +1
	# for numeric values only
	def self.increase(key)
	  value = Store.where(a_key: key).limit(1).pluck(:a_value).first
		if value.blank? # was zero
		  value = 1
		else
		  value = value.to_i + 1
		end
	  Store.where(a_key: key).first_or_initialize.update(a_value: value.to_s)
	end
	
	# equivalent of + amount
	# for numeric values only
	def self.increase_by(key, amount)
	  value = Store.where(a_key: key).limit(1).pluck(:a_value).first
		if value.blank? # was zero
		  value = amount.to_i
		else
		  value = value.to_i + amount.to_i
		end
	  Store.where(a_key: key).first_or_initialize.update(a_value: value.to_s)
	end
	
	def self.show
	  Store.order("a_key ASC").pluck(:a_key, :a_value)
	end
	
	#---------------------------------------
	# S3 Storage
	# used to maintain e.g. the list of deleted user ids (dev_deleted.dat and prod_deleted.dat)
	#---------------------------------------
	
	def self.s3_append(filename, value)
		bucket = S3_BUCKET
		raise "Remote storage operation aborted. S3 bucket not found." unless bucket.exists?
		obj = bucket.object(filename) 
		raise "Remote storage operation aborted. File not found." unless obj.exists?
		content = obj.get.body.read
		content += "\n" + value
		if obj.put(body: content)
		  content
		else
		  false
		end
	end
	
	def self.s3_read(filename)
		bucket = S3_BUCKET
		raise "Remote read operation aborted. S3 bucket not found." unless bucket.exists?
		raise "Remote read operation aborted. File not found." unless bucket.object(filename).exists?
		obj = bucket.object(filename)
		obj.get.body.read
	end
	
	def self.s3_write(filename, content)
		bucket = S3_BUCKET
		raise "Remote storage operation aborted. S3 bucket not found." unless bucket.exists?
		obj = bucket.object(filename) 
		obj.put(body: content)
	end
end
