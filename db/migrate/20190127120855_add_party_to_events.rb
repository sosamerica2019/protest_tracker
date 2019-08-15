class AddPartyToEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :events, :party, :string, limit: 50
  end
end
