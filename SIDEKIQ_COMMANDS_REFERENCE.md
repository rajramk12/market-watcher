# Sidekiq Configuration and Commands Reference

## Starting Sidekiq

### Basic Start
```bash
bundle exec sidekiq
```

### Recommended for Development
```bash
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```

### With Verbose Logging
```bash
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -v -l log/sidekiq.log
```

### High Performance (Production-like)
```bash
bundle exec sidekiq -c 25 -q ingest,10 -q db_write,5 -q default,2 -l log/sidekiq.log
```

### Single Queue (Testing)
```bash
bundle exec sidekiq -q ingest
```

## Command Line Options Explained

| Option | Example | Meaning |
|--------|---------|---------|
| `-c` | `-c 10` | 10 concurrent threads |
| `-q` | `-q ingest,5` | Process 'ingest' queue with weight 5 |
| `-l` | `-l log/sidekiq.log` | Log to file |
| `-v` | (flag) | Verbose logging |
| `-e` | `-e production` | Environment |
| `--pidfile` | `--pidfile tmp/sidekiq.pid` | PID file location |
| `--timeout` | `--timeout 20` | Job timeout in seconds |

## Queue Configuration

### Three Queues Used

1. **ingest** - Priority 5 (highest)
   - CsvUploadWorker
   - DailyBhavcopyFetcherWorker
   - Fetch data from external sources

2. **db_write** - Priority 3 (medium)
   - UpsertDailyPricesWorker
   - Write data to database

3. **default** - Priority 1 (lowest)
   - Other background jobs

### Weight System

```
-q ingest,5 -q db_write,3 -q default,1
```

Means:
- Process 5 jobs from 'ingest' queue
- Then 3 jobs from 'db_write' queue
- Then 1 job from 'default' queue
- Repeat

## Rails Console Commands

### Initialize Sidekiq in Console
```ruby
require 'sidekiq'
```

### View Statistics
```ruby
stats = Sidekiq::Stats.new
stats.to_h
# or specific stats:
puts "Processed: #{stats.processed}"
puts "Failed: #{stats.failed}"
puts "Enqueued: #{stats.enqueued}"
puts "Workers: #{stats.workers_size}"
```

### Check Queue Depth
```ruby
ingest = Sidekiq::Queue.new('ingest')
puts "Size: #{ingest.size}"
puts "Latency: #{ingest.latency}s"

db_write = Sidekiq::Queue.new('db_write')
puts "Size: #{db_write.size}"
```

### View Jobs in Queue
```ruby
queue = Sidekiq::Queue.new('ingest')
queue.each do |job|
  puts "#{job['class']} - #{job['created_at']}"
  puts "Args: #{job['args'].inspect}"
end

# View first job
puts queue.first.to_h
```

### View Failed Jobs
```ruby
dead = Sidekiq::DeadSet.new
puts "Failed jobs: #{dead.size}"

dead.each do |job|
  puts "Class: #{job['class']}"
  puts "Error: #{job['error_message']}"
  puts "---"
end
```

### Retry Failed Jobs
```ruby
# Retry all
Sidekiq::DeadSet.new.each(&:retry)

# Retry specific job
dead = Sidekiq::DeadSet.new
dead.first.retry
```

### Clear Queues
```ruby
# Clear specific queue
Sidekiq::Queue.new('ingest').clear

# Clear all failed jobs
Sidekiq::DeadSet.new.clear
```

### Enqueue Jobs Manually
```ruby
# Simple job
DailyBhavcopyFetcherWorker.perform_async('NSE')

# With date parameter
DailyBhavcopyFetcherWorker.perform_async('NSE', '2025-12-20')

# CSV upload
CsvUploadWorker.perform_async('/path/to/file.csv')

# Batch of daily prices
rows = [{stock: 'TCS', ...}, {stock: 'INFY', ...}]
UpsertDailyPricesWorker.perform_async(rows)
```

### Schedule Job for Later
```ruby
# In 1 hour
DailyBhavcopyFetcherWorker.perform_in(1.hour, 'NSE')

# At specific time
DailyBhavcopyFetcherWorker.perform_at(Time.new(2025, 12, 20, 16, 0, 0), 'NSE')

# In 30 minutes
CsvUploadWorker.perform_in(30.minutes, '/path/to/file.csv')
```

### View Active Workers
```ruby
processes = Sidekiq::ProcessSet.new
processes.each do |process|
  puts "Process: #{process['pid']}"
  puts "Workers: #{process['busy']}"
  puts "Concurrency: #{process['concurrency']}"

  process['info']['queues'].each do |queue|
    puts "  - #{queue}"
  end
end
```

## Monitoring Commands

### Watch Statistics Live
```ruby
# In Rails console
loop do
  system('clear')
  stats = Sidekiq::Stats.new
  puts "#{Time.now}"
  puts "Processed: #{stats.processed}"
  puts "Failed: #{stats.failed}"
  puts "Enqueued: #{stats.enqueued}"

  ['ingest', 'db_write', 'default'].each do |queue_name|
    queue = Sidekiq::Queue.new(queue_name)
    puts "#{queue_name}: #{queue.size} jobs (latency: #{queue.latency}s)"
  end

  sleep 2
end
```

### Check Redis Memory
```bash
redis-cli INFO memory
```

### Monitor Specific Worker
```bash
tail -f log/sidekiq.log | grep UpsertDailyPricesWorker
tail -f log/sidekiq.log | grep DailyBhavcopyFetcherWorker
tail -f log/sidekiq.log | grep "error\|Error\|ERROR"
```

## Troubleshooting Commands

### Is Redis Running?
```bash
redis-cli ping
# Should return: PONG
```

### Is Sidekiq Running?
```bash
ps aux | grep sidekiq

# Kill and restart if hung
pkill -f 'bundle exec sidekiq'
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3
```

### Check Sidekiq Status
```ruby
# In Rails console
puts "Sidekiq running: #{Sidekiq::Api.workers.size > 0}"
```

### Clear Everything (CAUTION!)
```ruby
# Clear all queues
Sidekiq::Queue.all.each(&:clear)

# Clear dead set
Sidekiq::DeadSet.new.clear

# WARNING: This deletes all pending jobs!
```

### Find Job by Class
```ruby
queue = Sidekiq::Queue.new('ingest')
queue.select { |job| job['class'] == 'DailyBhavcopyFetcherWorker' }
```

### Get Job Details
```ruby
queue = Sidekiq::Queue.new('ingest')
job = queue.first

puts "JID: #{job['jid']}"
puts "Class: #{job['class']}"
puts "Args: #{job['args']}"
puts "Retry: #{job['retry']}"
puts "Created: #{job['created_at']}"
puts "Enqueued: #{job['enqueued_at']}"
```

## Configuration File Example

If using `config/sidekiq.yml`:

```yaml
---
development:
  concurrency: 10
  timeout: 30
  :max_dead_count: 0
  :queues:
    - [ingest, 5]
    - [db_write, 3]
    - [default, 1]

production:
  concurrency: 25
  timeout: 60
  :queues:
    - [ingest, 10]
    - [db_write, 5]
    - [default, 2]
```

Load with:
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

## Systemd Service (Production)

Create `/etc/systemd/system/sidekiq.service`:

```ini
[Unit]
Description=Sidekiq
After=network.target

[Service]
Type=simple
WorkingDirectory=/path/to/app
ExecStart=/bin/bash -lc 'cd /path/to/app && bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:
```bash
sudo systemctl daemon-reload
sudo systemctl start sidekiq
sudo systemctl enable sidekiq  # Start on boot
sudo systemctl status sidekiq
```

## Best Practices

### 1. Always Use Concurrency Matching CPU Cores
```bash
# For 4-core CPU: use -c 10-20
# For 8-core CPU: use -c 20-40
bundle exec sidekiq -c 10
```

### 2. Monitor Memory Usage
```bash
# Watch memory in top
top -p $(pgrep -f 'bundle exec sidekiq')
```

### 3. Use Separate Terminal
```bash
# Terminal 1: Rails
rails server

# Terminal 2: Sidekiq
bundle exec sidekiq

# Terminal 3: Monitor
tail -f log/sidekiq.log
```

### 4. Log Rotation
Configure logrotate for `log/sidekiq.log` to prevent disk full

### 5. Health Checks
Monitor that:
- Process is running: `ps aux | grep sidekiq`
- Redis accessible: `redis-cli ping`
- Queue not backed up: `Sidekiq::Queue.new('ingest').size < 1000`

## Quick Copy-Paste Commands

### Start Development Setup (3 terminals)
```bash
# Terminal 1
rails server

# Terminal 2
redis-server

# Terminal 3
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log -v
```

### Check Everything in Console
```ruby
require 'sidekiq'

puts "=== Sidekiq Status ==="
stats = Sidekiq::Stats.new
puts "Processed: #{stats.processed}, Failed: #{stats.failed}, Enqueued: #{stats.enqueued}"

%w[ingest db_write default].each do |q|
  queue = Sidekiq::Queue.new(q)
  puts "#{q}: #{queue.size} (latency: #{queue.latency}s)"
end

dead = Sidekiq::DeadSet.new
puts "Dead: #{dead.size}"
```

### Trigger and Monitor
```bash
# Terminal 1
bundle exec rake bhav:fetch[NSE]

# Terminal 2
tail -f log/sidekiq.log

# Terminal 3
open http://localhost:3000/admin/sidekiq
```

### Clear and Retry
```ruby
require 'sidekiq'
puts "Retrying #{Sidekiq::DeadSet.new.size} failed jobs..."
Sidekiq::DeadSet.new.each(&:retry)
puts "Done! Check logs for details."
```

---

## Reference Summary

**Start Sidekiq:**
```bash
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3
```

**Check Status:**
```ruby
Sidekiq::Stats.new.to_h
```

**View Dashboard:**
```
http://localhost:3000/admin/sidekiq
```

**Watch Logs:**
```bash
tail -f log/sidekiq.log
```

**Trigger Test Job:**
```bash
bundle exec rake bhav:fetch[NSE]
```

**Retry Failed:**
```ruby
Sidekiq::DeadSet.new.each(&:retry)
```
