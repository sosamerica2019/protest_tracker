class AddReferToUser < ActiveRecord::Migration[4.2]
  def change
	  add_column :users, :refer, :string, :limit => 50, :default => nil
  end
end
