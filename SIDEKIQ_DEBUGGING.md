# Sidekiq Daily Bhav Processing - Debugging Guide

## Current Issue

Jobs are enqueued in Sidekiq but not transitioning to "processed" state. This guide helps identify where processing fails.

## Checklist for Debugging

### 1. Verify Sidekiq is Running

```bash
# Check if Sidekiq process is active
ps aux | grep sidekiq

# You should see something like:
# bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3

# If not running, start it:
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -l log/sidekiq.log
```

### 2. Check Redis Connection

```bash
# Verify Redis is running
redis-cli ping
# Should return: PONG

# Check Redis info
redis-cli INFO

# Check Sidekiq jobs in Redis
redis-cli KEYS "*"  # List all keys
redis-cli LLEN sidekiq:queue:ingest  # Check ingest queue size
```

### 3. View Sidekiq Logs

```bash
# Real-time logs
tail -f log/sidekiq.log

# Search for specific worker
tail -f log/sidekiq.log | grep DailyBhavcopyFetcherWorker
tail -f log/sidekiq.log | grep UpsertDailyPricesWorker

# Search for errors
tail -f log/development.log | grep -i "error\|exception"
```

### 4. Check Admin Dashboard

Visit: `http://localhost:3000/admin/sidekiq`

Look for:
- **Processed**: Should be increasing as jobs complete
- **Failed**: Jobs stuck here indicate errors
- **Enqueued**: Should decrease as jobs process
- **Workers**: Should show active workers and their current job

### 5. Check Rails Console

```ruby
# In rails console:
require 'sidekiq'

# Overall stats
stats = Sidekiq::Stats.new
puts "Enqueued: #{stats.enqueued}"
puts "Processed: #{stats.processed}"
puts "Failed: #{stats.failed}"
puts "Workers active: #{stats.workers_size}"

# Check ingest queue
ingest = Sidekiq::Queue.new('ingest')
puts "Ingest queue size: #{ingest.size}"
puts "Ingest latency: #{ingest.latency}s"

# View first job details
if ingest.size > 0
  job = ingest.first
  puts "First job: #{job['class']}"
  puts "Job details: #{job.to_h}"
end

# Check db_write queue
db_write = Sidekiq::Queue.new('db_write')
puts "DB Write queue size: #{db_write.size}"

# Check dead letter queue (failed jobs)
dead = Sidekiq::DeadSet.new
puts "Dead jobs: #{dead.size}"
if dead.size > 0
  puts "First dead job: #{dead.first.to_h}"
end
```

## Specific Worker Issues

### DailyBhavcopyFetcherWorker Not Processing

**Symptoms:**
- Job stays in ingest queue
- No logs appear in sidekiq.log

**Debugging Steps:**

1. **Check if Exchange exists**
   ```ruby
   Exchange.find_by(code: 'NSE')
   # Should return exchange record, not nil
   ```

2. **Check ExchangeIngestService**
   ```ruby
   # Verify service can be loaded
   require_relative '../../app/services/exchange_ingest_service'
   service = ExchangeIngestService.new(Exchange.find_by(code: 'NSE'))

   # Try fetching data
   data = service.fetch_eod(Date.today)
   puts "Rows returned: #{data.size}"
   ```

3. **Manually test the worker**
   ```ruby
   # In rails console
   DailyBhavcopyFetcherWorker.new.perform('NSE', Date.today.to_s)
   # This should print logs to console
   ```

4. **Check for missing columns**
   ```ruby
   row = { 'SYMBOL' => 'TCS', 'DATE1' => '2025-12-19', ... }
   BhavcopyRowMapper.map(row)
   # If error, check which column is missing
   ```

### UpsertDailyPricesWorker Not Processing

**Symptoms:**
- Jobs from DailyBhavcopyFetcher not creating records
- No logs visible

**Debugging Steps:**

1. **Check if Stock exists**
   ```ruby
   Stock.find_by(exchange_id: 1, stock: 'TCS')
   # Should return stock record
   ```

2. **Manually test the worker**
   ```ruby
   rows = [
     {
       'stock' => 'TCS',
       'trade_date' => '2025-12-19',
       'exchange_id' => 1,
       'prev_close' => 100.00,
       'close_price' => 102.50,
       # ... other fields ...
     }
   ]
   UpsertDailyPricesWorker.new.perform(rows)
   ```

3. **Check for database errors**
   ```ruby
   # Look at DailyPrice validations
   DailyPrice.create(stock_id: 1, trade_date: Date.today)
   # Should show validation errors
   ```

4. **Check unique constraint**
   ```ruby
   # Try duplicate insert
   DailyPrice.upsert({
     stock_id: 1,
     trade_date: Date.today,
     close_price: 100.00,
     # ... other fields ...
   }, unique_by: [:stock_id, :trade_date])
   ```

## Common Errors and Solutions

### "RecordNotFound: Couldn't find Exchange"

**Cause:** Exchange code not found in database

**Solution:**
```ruby
# Check available exchanges
Exchange.all.pluck(:code)

# Create missing exchange
Exchange.create!(code: 'NSE', name: 'National Stock Exchange')
```

### "uninitialized constant ExchangeIngestService"

**Cause:** Service not autoloaded

**Solution:**
```bash
# Verify file exists
ls -la app/services/exchange_ingest_service.rb

# Force autoload in Rails
require_relative 'app/services/exchange_ingest_service'
```

### "Validation failed: stock can't be blank"

**Cause:** Stock mapper returning empty 'stock' field

**Solution:**
1. Check CSV has SYMBOL column
2. Verify mapper receives correct data
3. Check unique constraint isn't being violated

### "Error: Lost connection to MySQL server during query"

**Cause:** Long-running queries or connection timeout

**Solution:**
```ruby
# Check database connection
ActiveRecord::Base.connection.active?

# Reconnect
ActiveRecord::Base.connection.reconnect!

# Verify connection pool settings
ActiveRecord::Base.connection_pool.disconnect!
```

## Log Analysis

### Example Successful Flow

```
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] === Starting Daily Bhavcopy Fetch ===
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] Exchange: NSE, Date: 2025-12-19
2025-12-19 15:30:01 [DailyBhavcopyFetcherWorker] Found exchange: National Stock Exchange (NSE)
2025-12-19 15:30:01 [DailyBhavcopyFetcherWorker] Processing date: 2025-12-19
2025-12-19 15:30:02 [DailyBhavcopyFetcherWorker] Fetched 500 rows from ingest service
2025-12-19 15:30:02 [DailyBhavcopyFetcherWorker] Mapped 500 rows
2025-12-19 15:30:02 [DailyBhavcopyFetcherWorker] Queued slice 1 with 500 rows
2025-12-19 15:30:02 [DailyBhavcopyFetcherWorker] === Daily Bhavcopy Fetch Complete ===
2025-12-19 15:30:03 [UpsertDailyPricesWorker] === Starting Daily Prices Upsert ===
2025-12-19 15:30:03 [UpsertDailyPricesWorker] Processing 500 rows
2025-12-19 15:30:05 [UpsertDailyPricesWorker] Successfully upserted: 500, Errors: 0
2025-12-19 15:30:05 [UpsertDailyPricesWorker] === Daily Prices Upsert Complete ===
```

### Example Error Flow

```
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] === Starting Daily Bhavcopy Fetch ===
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] Exchange: NSE, Date: 2025-12-19
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] Exchange not found: NSE
2025-12-19 15:30:00 [DailyBhavcopyFetcherWorker] Backtrace: ...
[Job marked as FAILED]
```

## Performance Monitoring

```ruby
# Monitor queue depth
loop do
  require 'sidekiq'
  stats = Sidekiq::Stats.new
  puts "#{Time.now} - Enqueued: #{stats.enqueued}, Processed: #{stats.processed}, Workers: #{stats.workers_size}"
  sleep 5
end
```

## Manual Retry of Failed Jobs

```ruby
require 'sidekiq'

# View failed jobs
dead_set = Sidekiq::DeadSet.new
puts "Failed jobs: #{dead_set.size}"

dead_set.each do |job|
  puts "Job: #{job['class']}, Args: #{job['args'].inspect}"
  puts "Error: #{job['error_message']}"
  puts "---"
end

# Retry all failed jobs
dead_set.each(&:retry)

# Or retry specific job
dead_set.first.retry if dead_set.size > 0
```

## Next Steps

1. **Run Sidekiq with verbose logging:**
   ```bash
   bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -v log/sidekiq.log
   ```

2. **Enqueue test job:**
   ```bash
   bundle exec rake bhav:fetch[NSE]
   ```

3. **Monitor logs in real-time:**
   ```bash
   tail -f log/sidekiq.log
   ```

4. **Check dashboard at:**
   ```
   http://localhost:3000/admin/sidekiq
   ```

5. **If still failing, check:**
   - Rails console for manual worker test
   - Database connection with `ActiveRecord::Base.connection.active?`
   - Redis with `redis-cli PING`
   - Rails logs for exceptions: `tail -f log/development.log | grep -i error`
