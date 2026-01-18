# config/initializers/sidekiq.rb
Sidekiq.configure_server do |config|
  redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
  config.redis = { url: redis_url }
end

Sidekiq.configure_client do |config|
  redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/1')
  config.redis = { url: redis_url }
end
