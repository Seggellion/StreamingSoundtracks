module Api
    class SchedulerController < ApplicationController

        def next_track
            # Atomic increment in Redis (Memorystore)
            counter = REDIS.incr("radio:song_counter")
            
            track_type = (counter % 11 == 0) ? :advertisement : :music
            track = Track.pick_random(type: track_type)

            # Mark as played so it rotates to the back of the line
            track.update(last_played_at: Time.current)

            render json: {
            id: track.id,
            url: GcsSignedUrlService.generate(track.gcs_path),
            metadata: { artist: track.artist, title: track.title }
            }
        end

    end
end