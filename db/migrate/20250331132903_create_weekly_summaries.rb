# in db/migrate/TIMESTAMP_create_weekly_summaries.rb
class CreateWeeklySummaries < ActiveRecord::Migration[7.0]
  def change
    create_table :weekly_summaries do |t|
      t.date :week_start, null: false
      t.references :project, null: true, foreign_key: true

      t.timestamps
    end
    
    # Compound index to ensure uniqueness of week_start per project (or global)
    add_index :weekly_summaries, [:week_start, :project_id], unique: true
  end
end