class AddChannelIdToComments < ActiveRecord::Migration[7.0]
  def change
    # Add the column without NOT NULL constraint first
    add_reference :comments, :channel, foreign_key: true

    # Assign a default value for existing rows
    general_channel = Channel.find_or_create_by(name: "General Comments")
    Comment.update_all(channel_id: general_channel.id)

    # Change the column to enforce NOT NULL
    change_column_null :comments, :channel_id, false
  end
end
