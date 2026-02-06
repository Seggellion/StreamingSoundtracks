module Api
    class SchedulerController < ApplicationController

        def next_track
            # 1. Check the Ad Counter in Redis
            song_count = REDIS.incr("radio:song_counter")
            
            if song_count % 11 == 0
            track = Track.where(is_ad: true).order("RANDOM()").first
            else
            # 2. Get the "Least Recently Played" music track
            track = Track.where(is_ad: false)
                        .order(last_played_at: :asc, play_count: :asc)
                        .first
            end

            if track
            track.increment!(:play_count)
            track.update(last_played_at: Time.current)
            
            # Return the GCS path in a format Liquidsoap expects
            render plain: "gcs:#{track.file_path}"
            else
            head :not_found
            end
        end

    end
end