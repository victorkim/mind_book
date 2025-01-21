class RenameOldNameToNewName < ActiveRecord::Migration[7.1]
  def change
    rename_column :comments, :comments, :date
  end
end
