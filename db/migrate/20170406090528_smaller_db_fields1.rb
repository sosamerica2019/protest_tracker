class SmallerDbFields1 < ActiveRecord::Migration[4.2]
  def up
	  User.where("gender NOT IN (?)", ["male", "female", "prefer not to say", "other", nil]).update_all("gender = 'prefer not to say'")
    change_column :users, :gender, :string, :limit => 20
    User.where("length(country) > 2").update_all("country = 'AX'")
		change_column :users, :country, :string, :limit => 2
		User.where("length(language) > 20").update_all("language = 'English'")
		change_column :users, :language, :string, :limit => 20
		User.where("length(postal_code) > 20").update_all("postal_code = ''")
		change_column :users, :postal_code, :string, :limit => 20
		User.where("length(twitter) > 20").update_all("twitter = ''")
		change_column :users, :twitter, :string, :limit => 20
    User.where("length(city) > 50").update_all("city = ''")
		change_column :users, :city, :string, :limit => 50
		change_column :users, :confirmation_token, :string, :limit => 100
  end

  def down
  end
end