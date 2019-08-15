class ExtendUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :admin_level, :integer
	add_column :users, :personal_name, :string
	add_column :users, :family_name, :string
	add_column :users, :mobile, :string
	add_column :users, :city, :string
	add_column :users, :country, :string
	add_column :users, :gender, :string
	add_column :users, :twitter, :string
	add_column :users, :language, :string
	add_column :users, :volunteer, :integer
  end
end
