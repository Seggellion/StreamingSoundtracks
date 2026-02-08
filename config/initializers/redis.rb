
# Use a specific environment variable for the Redis Host/Port 
# Google Memorystore gives you a private IP, not a full 'redis://' URL by default.
redis_host = ENV.fetch("REDIS_HOST", "127.0.0.1")
redis_port = ENV.fetch("REDIS_PORT", "6379")

# Build the connection
# Note: Memorystore (Basic/Standard) usually doesn't use SSL inside the VPC 
# unless you specifically enabled 'Transit Encryption'
REDIS = Redis.new(
  host: redis_host,
  port: redis_port,
  # Only use SSL if Transit Encryption is enabled on your instance
  ssl: ENV["REDIS_USE_SSL"] == "true",
  ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE }
)