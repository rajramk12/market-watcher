# Daily Bhav Data Ingestion Guide

This guide explains how the market data ingestion pipeline works and how to use it.

## Architecture Overview

The system has three main components:

1. **CsvUploadWorker** - Processes uploaded CSV files from admin interface
2. **DailyBhavcopyFetcherWorker** - Automatically fetches daily market data
3. **UpsertDailyPricesWorker** - Batch writes data to database

## Workflow

### CSV Upload Flow (Manual)

```
User uploads CSV file via /admin/uploads
                    ↓
        CsvUploadWorker.perform_async(file_path)
                    ↓
        Reads CSV, maps rows with BhavcopyRowMapper
                    ↓
        Creates/updates Stock and DailyPrice records
                    ↓
        Job marked as complete in Sidekiq dashboard
```

### Daily Bhav Fetch Flow (Automatic/Manual)

```
DailyBhavcopyFetcherWorker.perform_async(exchange_code, date)
                    ↓
        Fetches data from ExchangeIngestService
                    ↓
        Maps rows with BhavcopyRowMapper
                    ↓
        Enqueues UpsertDailyPricesWorker in 500-row slices
                    ↓
        UpsertDailyPricesWorker processes each slice
                    ↓
        Data upserted to daily_prices table with unique constraint
```

## Running Sidekiq

Sidekiq processes jobs from Redis queues. You need to run Sidekiq in a separate terminal:

```bash
# In a separate terminal window:
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1

# Breaking down the command:
# -c 10           : Max 10 concurrent threads
# -q ingest,5     : Process 'ingest' queue with 5x weight
# -q db_write,3   : Process 'db_write' queue with 3x weight
# -q default,1    : Process 'default' queue with 1x weight
```

The queue weights mean Sidekiq will process 5 jobs from 'ingest' for every 3 from 'db_write' and 1 from 'default'.

## Manual Job Triggering

### Fetch data for a specific exchange

```bash
# Using rake task (recommended)
bundle exec rake bhav:fetch[NSE]
bundle exec rake bhav:fetch[NSE,2025-12-20]

# Using Rails console
rails console
DailyBhavcopyFetcherWorker.perform_async('NSE')
DailyBhavcopyFetcherWorker.perform_async('NSE', '2025-12-20')
```

### Fetch data for all active exchanges

```bash
bundle exec rake bhav:fetch_all
bundle exec rake bhav:fetch_all[2025-12-20]
```

### Check job status

```bash
bundle exec rake bhav:status

# Or in Rails console:
require 'sidekiq'
stats = Sidekiq::Stats.new
puts "Enqueued: #{stats.enqueued}"
puts "Processed: #{stats.processed}"
puts "Failed: #{stats.failed}"

queue = Sidekiq::Queue.new('ingest')
puts "Ingest queue size: #{queue.size}"
```

## Monitoring

### Admin Dashboard

Visit `http://localhost:3000/admin/sidekiq` to see:

- Overall statistics (enqueued, processed, failed jobs)
- Active workers and their current jobs
- Job queues with sizes and latencies
- Dead letter queue (failed jobs)
- Action buttons to clear or retry failed jobs

### Sidekiq Web Console (Alternative)

If you mount Sidekiq::Web, visit `http://localhost:3000/admin/sidekiq/dashboard`

### Rails Console

```ruby
require 'sidekiq'

# Get statistics
stats = Sidekiq::Stats.new
puts "Stats: #{stats.to_h}"

# Check specific queue
ingest_queue = Sidekiq::Queue.new('ingest')
puts "Ingest queue: #{ingest_queue.size} jobs"

# View first job details
puts ingest_queue.first.to_h if ingest_queue.size > 0

# Get dead letter queue (failed jobs)
dead = Sidekiq::DeadSet.new
puts "Dead jobs: #{dead.size}"
dead.each { |job| puts job.to_h }

# Retry all dead jobs
Sidekiq::DeadSet.new.each(&:retry)
```

## Troubleshooting

### Jobs enqueued but not processing

**Symptoms:** Jobs appear in Sidekiq dashboard but never transition to "processed"

**Solutions:**

1. **Sidekiq worker not running**
   - Check if `bundle exec sidekiq` is running in a terminal
   - Start it with: `bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3`

2. **Redis not accessible**
   - Verify Redis is running: `redis-cli ping` should return PONG
   - Check Redis connection in logs: `tail -f log/development.log`

3. **Worker errors (silent failures)**
   - Check Sidekiq logs for error messages
   - View detailed job info in dashboard
   - Check Rails log: `tail -f log/development.log`
   - View dead letter queue: `Sidekiq::DeadSet.new.each { |job| puts job.to_h }`

4. **Missing service or data**
   - ExchangeIngestService is stubbed - implement your data source
   - DailyBhavcopyFetcherWorker calls this service; if it returns empty, no data is processed
   - UpsertDailyPricesWorker logs indicate which stocks fail to save

### View Worker Logs

Both workers log extensively:

```bash
# Watch logs in real-time
tail -f log/development.log | grep -E "CsvUploadWorker|DailyBhavcopyFetcherWorker|UpsertDailyPricesWorker"
```

Example log output:
```
[CsvUploadWorker] === Starting CSV Upload ===
[CsvUploadWorker] File path: /uploads/bhav.csv
[CsvUploadWorker] Processed 100 rows...
[CsvUploadWorker] Successfully processed 500 rows, 2 errors
[CsvUploadWorker] === CSV Upload Complete ===

[DailyBhavcopyFetcherWorker] === Starting Daily Bhavcopy Fetch ===
[DailyBhavcopyFetcherWorker] Exchange: NSE, Date: 2025-12-20
[DailyBhavcopyFetcherWorker] Fetched 1500 rows from ingest service
[DailyBhavcopyFetcherWorker] Mapped 1500 rows
[DailyBhavcopyFetcherWorker] Queued slice 1 with 500 rows
[DailyBhavcopyFetcherWorker] === Daily Bhavcopy Fetch Complete ===

[UpsertDailyPricesWorker] === Starting Daily Prices Upsert ===
[UpsertDailyPricesWorker] Processing 500 rows
[UpsertDailyPricesWorker] Successfully upserted: 500, Errors: 0
[UpsertDailyPricesWorker] === Daily Prices Upsert Complete ===
```

### Clear failed jobs

```bash
# Via rake task
bundle exec rake bhav:status

# Via Rails console
require 'sidekiq'
Sidekiq::Queue.new('ingest').clear  # Clear entire ingest queue
Sidekiq::DeadSet.new.clear          # Clear dead letter queue
Sidekiq::DeadSet.new.each(&:retry)  # Retry all failed jobs
```

## Database Schema

The daily_prices table has these fields:

- `stock_id` (FK to stocks)
- `trade_date` (date, part of unique constraint)
- `series` (string)
- `prev_close`, `open_price`, `high_price`, `low_price`, `last_price`, `close_price` (decimals)
- `avg_price`, `traded_qty`, `turnover_lacs`, `no_of_trades` (trading metrics)
- `delivered_qty`, `delivery_percent` (delivery metrics)
- **`change_percentage`** (calculated: (close - prev_close) / prev_close * 100)
- **`change_absolute`** (calculated: close_price - prev_close)
- **`total_combined_qty_amount`** (calculated: traded_qty * avg_price)

Unique constraint: `[stock_id, trade_date]` - ensures one record per stock per day.

## Implementation Notes

### CSV Format

Expected columns in uploaded CSV (from BhavcopyRowMapper):
- SYMBOL
- SERIES
- DATE1
- PREV_CLOSE
- OPEN_PRICE
- HIGH_PRICE
- LOW_PRICE
- LAST_PRICE
- CLOSE_PRICE
- AVG_PRICE
- TTL_TRD_QNTY
- TURNOVER_LACS
- NO_OF_TRADES
- DELIV_QTY
- DELIV_PER

### Retry Strategy

- CsvUploadWorker: 3 retries (ingest queue)
- DailyBhavcopyFetcherWorker: 3 retries (ingest queue)
- UpsertDailyPricesWorker: 3 retries (db_write queue)

Failed jobs after all retries go to dead letter queue.

### Performance Tips

1. Increase `-c` concurrency if workers are idle
2. Adjust queue weights based on load (`-q ingest,5 -q db_write,3`)
3. Monitor Redis memory: `redis-cli INFO memory`
4. Check database connections: Look for slow queries in logs
5. Batch size is 500 rows per UpsertDailyPricesWorker job

## Next Steps

1. **Implement ExchangeIngestService**
   - Replace stub in `app/services/exchange_ingest_service.rb`
   - Fetch data from NSE API or CSV endpoint
   - Return array of row hashes with expected column names

2. **Setup automatic scheduling** (optional)
   - Add `gem 'sidekiq-cron'` to Gemfile
   - Create config/sidekiq.yml with cron jobs
   - Run daily fetch at specific time (e.g., 4 PM IST)

3. **Add data validation**
   - Validate required fields before upsert
   - Skip invalid rows with logging
   - Create alerts for data quality issues

4. **Monitor and alert**
   - Setup alerts for failed jobs
   - Track data freshness (latest trade_date vs current date)
   - Monitor worker health and queue depths
