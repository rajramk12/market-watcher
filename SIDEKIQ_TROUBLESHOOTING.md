# Sidekiq Job Processing Troubleshooting Guide

## Problem: Jobs are Enqueued but Not Processing

### ✅ Quick Checklist

- [ ] **Redis is running** - Check port 6379
- [ ] **Sidekiq worker process is running** - Separate terminal window
- [ ] **Database connection is working** - Check logs for DB errors
- [ ] **File paths exist** - For CSV upload jobs
- [ ] **Worker class is correct** - Check job class name

---

## Step 1: Verify Redis Connection

### Check if Redis is running:
```bash
# Windows - with Docker
docker ps | grep redis
docker logs <container_id>

# Check Redis connection
redis-cli ping
# Should return: PONG
```

### If Redis is not running:
```bash
# Start Redis with Docker
docker run -d -p 6379:6379 redis:latest

# Or verify Docker service is running
docker ps
```

---

## Step 2: Start/Verify Sidekiq Worker

### In a new terminal window:
```bash
# Start Sidekiq with verbose logging
bundle exec sidekiq -c 5 -v

# You should see:
# Booting Sidekiq 7.x.x with 5 workers
# Started Sidekiq server...
```

### If you see connection errors:
```ruby
# In Rails console
require 'sidekiq'
Sidekiq.redis { |conn| conn.ping }
# Should return: "PONG"
```

### Check if Redis URL is correct:
```ruby
# In Rails console
require 'sidekiq'
puts ENV['REDIS_URL']
# Should show: redis://localhost:6379/1 (or your custom URL)
```

---

## Step 3: Monitor Job Processing

### Option A: Check in Rails Console
```ruby
# Start Rails console with proper environment
rails c

# IMPORTANT: Load Sidekiq first
require 'sidekiq'

# Now check queue status
Sidekiq::Queue.new('ingest').size  # Should decrease as jobs process

# Check stats
stats = Sidekiq::Stats.new
puts "Enqueued: #{stats.enqueued}"
puts "Processed: #{stats.processed}"
puts "Failed: #{stats.failed}"

# Check if workers are active
Sidekiq::Workers.new.each { |id, data| puts "Worker: #{id}, Queue: #{data['queue']}" }
```
```

### Option B: Use Web Dashboard
```
http://localhost:3000/admin/sidekiq
```
- Refresh every 5 seconds to see jobs being processed
- Watch "Processed" counter increase
- See active workers in the table

---

## Step 4: Common Issues & Solutions

### Issue 1: "Connection refused" - Redis not running
```bash
# Start Redis
docker run -d -p 6379:6379 redis:latest

# Verify connection
redis-cli ping
```

### Issue 2: Workers show but jobs not decreasing
Check if workers are actually running:
```ruby
# In Rails console
require 'sidekiq'
workers = Sidekiq::Workers.new
puts workers.size  # Should be > 0

# Check worker details
workers.each do |id, worker_data|
  puts "#{id}: #{worker_data['payload']['class']} on #{worker_data['queue']}"
end
```

### Issue 3: Jobs immediately fail
Check the logs in two places:

1. **Sidekiq terminal output:**
```bash
# Look for error messages in the Sidekiq window
```

2. **Rails logs:**
```bash
tail -f log/development.log

# Look for errors like:
# [ERROR] Error processing row: ...
# [ERROR] CSV Upload Failed: ...
```

3. **Dashboard Failed Jobs section:**
- Visit http://localhost:3000/admin/sidekiq
- Check "Failed Jobs" for error messages

### Issue 4: File not found error
```ruby
# In Rails console - test file path
file_path = '/path/to/bhav_data.csv'
File.exist?(file_path)  # Should return true

# List available files
Dir.glob('**/*.csv')
```

---

## Step 5: Test Manual Job Trigger

### Trigger a test job:
```ruby
# In Rails console
require 'sidekiq'
CsvUploadWorker.perform_async('/path/to/test.csv')

# Immediately check queue
Sidekiq::Queue.new('ingest').size  # Should be 1

# Wait 5 seconds and check again
sleep 5
Sidekiq::Queue.new('ingest').size  # Should be 0 if processing worked
```

### Check if job was processed:
```ruby
require 'sidekiq'
stats = Sidekiq::Stats.new
puts "Processed: #{stats.processed}"  # Should increase
```

---

## Step 6: Enable Debug Logging

### Edit config/environments/development.rb:
```ruby
# Add this
Sidekiq.logger.level = Logger::DEBUG
```

### Check logs while processing:
```bash
tail -f log/development.log

# Look for:
# === Starting CSV Upload ===
# Processed 100 rows...
# === CSV Upload Complete ===
```

---

## Step 7: Full Processing Workflow

### Terminal 1 - Start Rails Server:
```bash
rails s
```

### Terminal 2 - Start Sidekiq Worker:
```bash
bundle exec sidekiq -c 5 -v
```

### Terminal 3 - Upload CSV:
```bash
# Visit http://localhost:3000/admin/uploads
# Select a CSV file and upload
```

### Terminal 4 - Monitor (Optional):
```bash
rails c

# Once in console, require Sidekiq
require 'sidekiq'

# Watch processing
loop do
  stats = Sidekiq::Stats.new
  puts "Enqueued: #{stats.enqueued}, Processed: #{stats.processed}, Failed: #{stats.failed}"
  sleep 5
end
```

### Check Dashboard:
```
http://localhost:3000/admin/sidekiq
```

---

## Step 8: Expected Behavior

### ✅ Correct Processing Flow:
1. Upload CSV → Job enqueued (shows in ingest queue)
2. Sidekiq picks up job → Moves to active workers
3. Job processes rows → Logs show progress
4. Job completes → Moves from enqueued to processed
5. Database updated → Check with: `DailyPrice.count`

### 🔍 Monitor These Metrics:
- **Queue Size**: Should decrease over time
- **Processed Count**: Should increase
- **Active Workers**: Should show running jobs
- **Failed Jobs**: Should stay at 0 if no errors

---

## Quick Commands Reference

```bash
# Check Redis status
redis-cli ping

# Start Redis
docker run -d -p 6379:6379 redis:latest

# Start Sidekiq (separate terminal)
bundle exec sidekiq -c 5 -v

# Check logs
tail -f log/development.log

# Rails console checks
rails c
require 'sidekiq'
Sidekiq::Queue.new('ingest').size
Sidekiq::Stats.new
Sidekiq::Workers.new

# Clear all jobs (⚠️ Use cautiously!)
Sidekiq::Queue.new('ingest').clear
```

---

## Verify Database Updates

After jobs complete, verify data was inserted:

```ruby
# In Rails console
require 'sidekiq'
DailyPrice.count          # Check row count increased
DailyPrice.last 5         # View recent entries
Stock.count               # Check stocks were created
Stock.joins(:daily_prices).count  # Verify FK relationships
```

---

## If Nothing Works

1. **Check Sidekiq gem version:**
   ```bash
   bundle show sidekiq
   ```

2. **Ensure all gems are installed:**
   ```bash
   bundle install
   bundle exec rake db:migrate
   ```

3. **Restart everything:**
   ```bash
   # Stop: Ctrl+C in both terminals
   # Kill any hanging processes
   pkill -f sidekiq

   # Start fresh
   docker restart redis
   bundle exec sidekiq -c 5 -v
   rails s
   ```

4. **Check application logs:**
   ```bash
   cat log/development.log | grep -i error
   ```

---

## Success Indicators

- ✅ Queue size decreases
- ✅ Processed count increases
- ✅ No error messages in logs
- ✅ Database records created
- ✅ Failed jobs count stays at 0
- ✅ Dashboard shows job details
