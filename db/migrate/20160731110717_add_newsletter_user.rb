class AddNewsletterUser < ActiveRecord::Migration[4.2]
  def change
     add_column :users, :newsletter_only, :boolean
  end
end
