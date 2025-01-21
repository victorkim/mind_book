class RemoveColumnNameFromTableName < ActiveRecord::Migration[7.1]
  def change
    remove_column :comments, :comments, :date
  end
end
