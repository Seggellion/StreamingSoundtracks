# app/services/gcs_indexer_service.rb
class GcsIndexerService
  def self.call
    storage = Google::Cloud::Storage.new
    bucket  = storage.bucket "your-radio-bucket"
    files   = bucket.files(prefix: "music/")

    loop do
      batch = files.map do |f|
        next unless f.name.ends_with?(".wma")
        {
          file_path: f.name,
          file_size: f.size,
          updated_at: Time.current,
          created_at: Time.current
        }
      end.compact

      Track.upsert_all(batch, unique_by: :file_path) if batch.any?
      
      files = files.next or break
    end
  end
end