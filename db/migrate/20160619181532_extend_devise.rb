class ExtendDevise < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :unconfirmed_email, :string  # needed by Devise, even though it said it didn't
  end
end
