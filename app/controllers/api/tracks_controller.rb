module Api
  class TracksController < ApplicationController
    
    def next_track
      # 1. Randomized Ad Logic (Bypassing Redis)
      is_ad_time = (rand(1..11) == 1)
      target_type = is_ad_time ? 'advertisement' : 'music'
      
      # Dummy counter
      counter = 0 
      
      # 2. Fetch candidate
      track = Track.pick_random(type: target_type)

      # 3. Fallback Logic
      if track.nil? && target_type == 'advertisement'
        Rails.logger.warn("⚠️ Ad requested but none found. Falling back to Music.")
        track = Track.pick_random(type: 'music')
      end

      if track
        # 4. Mark as played
        track.update(last_played_at: Time.current, play_count: track.play_count + 1)

        # ---------------------------------------------------------
        # THE FIX: Use the Environment Variable Key if it exists
        # ---------------------------------------------------------
        storage = if ENV["GCS_KEY_JSON"]
                    # Parse the JSON string into a hash and use it as credentials
                    creds = JSON.parse(ENV["GCS_KEY_JSON"])
                    Google::Cloud::Storage.new(credentials: creds)
                  else
                    # Fallback for local development
                    Google::Cloud::Storage.new
                  end
        # ---------------------------------------------------------

        bucket  = storage.bucket("streamingsoundtracks")
        file    = bucket.file(track.gcs_path)

        # 5. Generate Signed URL
        # We don't need to manually specify 'issuer' here because
        # the JSON credentials object contains it automatically.
        signed_url = file.signed_url(
          method: "GET",
          expires: 15.minutes
        )

        render json: {
          status: "success",
          counter: counter,
          track_type: track.track_type,
          metadata: {
            artist: track.artist,
            title: track.title,
            duration_ms: track.duration_ms
          },
          url: signed_url
        }
      else
        render json: { status: "error", message: "No tracks found in library" }, status: :not_found
      end
    rescue StandardError => e
      Rails.logger.error("TRACK ERROR: #{e.message}")
      render json: { status: "error", message: e.message }, status: :internal_server_error
    end

  end
end