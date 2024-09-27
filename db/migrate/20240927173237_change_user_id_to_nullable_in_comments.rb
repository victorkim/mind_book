class ChangeUserIdToNullableInComments < ActiveRecord::Migration[7.1]
  def change
    change_column_null :comments, :user_id, true
  end
end
