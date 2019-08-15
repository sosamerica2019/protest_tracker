class VolunteerAbilitiesMinimum < ActiveRecord::Migration[4.2]
  def up
    change_column :users, :volunteer_abilities, :string, :default => ""
    User.where(:volunteer_abilities => nil).update_all("volunteer_abilities = ''")
  end
  
  def down
  end
end
