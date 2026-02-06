require "google/cloud/storage"

namespace :ss_indexer do
  desc "Ingest 160k files from streamingsoundtracks bucket"
  task sync: :environment do
    require_dependency Rails.root.join("app/models/track.rb").to_s unless defined?(Track)

    BUCKET_NAME = "streamingsoundtracks"
    # Focus only on the music directory
    MUSIC_PREFIX = "music/" 
    
    storage = Google::Cloud::Storage.new
    bucket  = storage.bucket(BUCKET_NAME, skip_lookup: true)
    
    batch_size  = 1000
    track_batch = []
    
    perform_upsert = ->(batch) {
      return if batch.empty?
      Track.upsert_all(batch, unique_by: :gcs_path)
      puts "Successfully upserted #{batch.size} tracks..."
    }

    puts "Scanning gs://#{BUCKET_NAME}/#{MUSIC_PREFIX}..."

    # Use the prefix: "music/" to start the search there
    bucket.files(prefix: MUSIC_PREFIX).all do |file|
      next if file.name.end_with?("/") # Skip folder placeholders

      # file.name is "music/Artist Name/Song Title.wma"
      # We remove the "music/" prefix for parsing
      clean_path = file.name.sub(/^#{MUSIC_PREFIX}/, "")
      path_parts = clean_path.split('/')
      
      # Now path_parts[0] is "Artist Name"
      # path_parts[-1] is "Song Title.wma"
      
      track_batch << {
        file_path:  file.name, # Using file.name as the unique file_path
        artist:     path_parts[0] || "Unknown Artist",
        title:      File.basename(path_parts[-1] || "Unknown Title", ".*"),
        gcs_path:   file.name,
        track_type: file.name.downcase.include?("advertisement") ? "advertisement" : "music",
        created_at: Time.current,
        updated_at: Time.current,
        properties: { size: file.size, content_type: file.content_type }
      }

      if track_batch.size >= batch_size
        perform_upsert.call(track_batch)
        track_batch.clear
      end
    end

    perform_upsert.call(track_batch)
    puts "Indexing complete. Total Tracks: #{Track.count}"
  end
end