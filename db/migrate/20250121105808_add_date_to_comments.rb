class AddDateToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :date, :date
  end
end
