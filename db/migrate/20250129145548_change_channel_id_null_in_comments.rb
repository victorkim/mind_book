class ChangeChannelIdNullInComments < ActiveRecord::Migration[7.0]
  def up
    change_column_null :comments, :channel_id, true
  end

  def down
    change_column_null :comments, :channel_id, false
  end
end
