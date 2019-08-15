class ExtendRegistration < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :postal_code, :string
    add_column :users, :birthdate, :date
    add_column :users, :volunteer_abilities, :string
    add_column :users, :volunteer_abilities_desc, :text
    add_column :users, :volunteer_hours_per_week, :string
  end
end