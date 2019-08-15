class CreatePrivileges < ActiveRecord::Migration[5.1]
  def change
    create_table :user_privileges do |t|
      t.string :privilege
			t.string :scope
      t.integer :user_id
			t.index ["user_id"], name: "index_user_privileges_on_user_id", unique: false
    end
		
		User.where("admin_level >= 8").each do |u|
		  UserPrivilege.quick_assign(u, "all")
		end
		
		User.where("admin_level >= 5 and admin_level < 8").each do |u|
		  UserPrivilege.quick_assign(u, "country_it")
		end
		
		User.where("admin_level >= 1 and admin_level < 5").each do |u|
		  UserPrivilege.quick_assign(u, "low")
		end
  end
end
