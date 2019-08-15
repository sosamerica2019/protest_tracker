class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :events do |t|
      t.string :title, limit: 100
      t.string :event_type, limit: 20
      t.integer :user_id
      t.string :organizer_name  # (DSC or personal name)
      t.string :rsvp_address  #  (email or link)
      t.datetime :event_start
      t.datetime :event_end
      t.string :location_name, limit: 50
      t.text :location_address
      t.string :location_city
      t.string :location_country, limit: 2
      t.point :location_geo
      t.integer :location_size
      t.integer :travel_distance  # x km [40km,  80km, 120, 160, 240, 320, 9999]
      t.text :description
      t.string :picture_url
      t.string :details_url
      t.string :tickets_url
      t.string :audience, limit: 1
      t.string :moderation, limit: 1

      t.timestamps
    end
  end
end
