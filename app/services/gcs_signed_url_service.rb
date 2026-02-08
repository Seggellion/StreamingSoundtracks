# app/services/gcs_signed_url_service.rb
require "google/cloud/storage"

class GcsSignedUrlService
  BUCKET_NAME = "streamingsoundtracks" # Ensure this matches your bucket

  def self.generate(object_key)
    return nil if object_key.blank?

    # 1. Initialize Storage (Lazy loaded)
    # Cloud Run automatically picks up credentials from the environment
    storage = Google::Cloud::Storage.new(project_id: "streamingsoundtracks")
    bucket  = storage.bucket(BUCKET_NAME, skip_lookup: true)

    # 2. Get reference to the file
    # object_key is passed from the DB (e.g., "music/Artist/Song.mp3")
    file = bucket.file(object_key)

    if file.nil?
      Rails.logger.error("[GcsSignedUrlService] File not found in bucket: #{object_key}")
      return nil
    end

    # 3. Generate Signed URL (V4)
    # Valid for 15 minutes to prevent link sharing
    file.signed_url(method: "GET", expires: 15.minutes.to_i, version: :v4)
  rescue StandardError => e
    Rails.logger.error("[GcsSignedUrlService] Error generating URL: #{e.message}")
    nil
  end
end