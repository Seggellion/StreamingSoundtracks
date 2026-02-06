class GcsSignedUrlService
  def self.generate(gcs_path)
    storage = Google::Cloud::Storage.new
    bucket = storage.bucket(ENV['GCS_BUCKET_NAME'])
    file = bucket.file(gcs_path)

    # Valid for 10 minutes (plenty for Liquidsoap to buffer)
    file.signed_url(method: "GET", expires: 600, version: :v4)
  end
end