class CreateTracks < ActiveRecord::Migration[8.0]
  def change
    create_table :tracks do |t|
      t.string   :file_path,   null: false 
      t.string   :md5_hash                 
      t.string   :artist
      t.string   :title
      t.integer  :duration_ms
      t.jsonb    :properties,  null: false, default: {}
      t.string   :gcs_path,    null: false
      t.datetime :last_played_at
      t.integer  :play_count,  null: false, default: 0
      t.string   :track_type,  default: 'music'

      t.timestamps
    end

    # Index for upsert_all logic
    add_index :tracks, :file_path, unique: true
    add_index :tracks, :gcs_path,  unique: true
    
    # Scheduler optimization
    add_index :tracks, [:last_played_at, :play_count], name: "idx_scheduler_optimization"
  end
end