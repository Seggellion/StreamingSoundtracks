# We bypass the s3:// protocol and use a direct URI
# Note: This will only work if the file is public or if we use 
# the GCS Interop settings we'll build into Rails tomorrow.
def get_test_request() = 
  request.create("https://storage.googleapis.com/streamingsoundtracks/music/test-track.wma")
end

test_file = request.dynamic(get_test_request)

output.file(%wav, "/tmp/test_output.wav", fallible=true, test_file)

thread.run.recurrent(delay=10.0, {
  log("Test complete. Shutting down...")
  shutdown()
  -1.0 
})