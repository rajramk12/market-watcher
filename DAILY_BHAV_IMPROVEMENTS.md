# Daily Bhav Processing Improvements - Summary

## Overview

This document summarizes the enhancements made to the daily bhav data ingestion pipeline to ensure reliable job processing and comprehensive logging.

## Changes Made

### 1. Enhanced UpsertDailyPricesWorker
**File:** `app/workers/upsert_daily_prices_worker.rb`

**Changes:**
- Added comprehensive logging at start and completion
- Added retry: 3 configuration for automatic retries on failure
- Added per-row error handling with detailed logging
- Track successful upserts vs errors
- Log backtrace for debugging

**Key Features:**
```ruby
logger.info "=== Starting Daily Prices Upsert ==="
logger.info "Processing #{rows.size} rows"
# ... process with error handling ...
logger.info "Successfully upserted: #{upserted_count}, Errors: #{error_count}"
```

### 2. Enhanced DailyBhavcopyFetcherWorker
**File:** `app/workers/daily_bhavcopy_fetcher_worker.rb`

**Changes:**
- Added comprehensive logging for all stages
- Added retry: 3 configuration
- Added structured error handling with specific exception types
- Logs exchange lookup, data fetching, mapping, and enqueueing steps
- Backtrace logging for debugging

**Key Features:**
```ruby
logger.info "=== Starting Daily Bhavcopy Fetch ==="
# Specific logging for each operation
logger.error "Failed to fetch data from ExchangeIngestService: #{e.message}"
```

### 3. Created ExchangeIngestService
**File:** `app/services/exchange_ingest_service.rb` (NEW)

**Purpose:** Stub service for fetching EOD data

**Current Implementation:**
- Returns empty array (stub for integration)
- Has logging infrastructure in place
- Ready for real API implementation

**Usage:**
```ruby
service = ExchangeIngestService.new(exchange)
rows = service.fetch_eod(date)
```

### 4. Fixed BhavcopyRowMapper
**File:** `app/services/bhavcopy_row_mapper.rb`

**Changes:**
- Removed incorrect `extras: row['extras'].to_json` field
- Ensures mapper returns only database-compatible fields
- All fields align with UpsertDailyPricesWorker expectations

### 5. Created Rake Tasks for Bhav Management
**File:** `lib/tasks/bhav.rake` (NEW)

**Available Tasks:**

```bash
# Fetch for specific exchange
bundle exec rake bhav:fetch[NSE]
bundle exec rake bhav:fetch[NSE,2025-12-20]

# Fetch for all active exchanges
bundle exec rake bhav:fetch_all
bundle exec rake bhav:fetch_all[2025-12-20]

# Check job status
bundle exec rake bhav:status
```

**Features:**
- User-friendly status messages
- Displays queue statistics
- Shows failed jobs in dead letter queue
- Supports environment variables for parameters

### 6. Created Database Migration
**File:** `db/migrate/20260119_fix_stocks_table_structure.rb` (NEW)

**Purpose:** Fix stocks table schema issue

**Changes:**
- Convert `stock_id` (BIGINT) to `stock` (STRING)
- Maintain proper unique constraint on (exchange_id, stock)
- Safe migration with error handling
- Data preservation and backfilling

**Note:** Run with: `bundle exec rake db:migrate`

### 7. Created Daily Bhav Ingestion Guide
**File:** `DAILY_BHAV_INGESTION.md` (NEW)

**Contents:**
- Architecture overview
- Workflow diagrams
- How to run Sidekiq
- Manual job triggering
- Monitoring instructions
- Troubleshooting guide
- Database schema reference
- Implementation notes

### 8. Created Sidekiq Debugging Guide
**File:** `SIDEKIQ_DEBUGGING.md` (NEW)

**Contents:**
- Comprehensive debugging checklist
- Worker-specific debugging steps
- Common errors and solutions
- Log analysis examples
- Performance monitoring
- Manual retry procedures

## Database Schema Status

### Calculated Fields (Added via migration 20260117)
✅ `change_percentage` - (close_price - prev_close) / prev_close * 100
✅ `change_absolute` - close_price - prev_close
✅ `total_combined_qty_amount` - traded_qty * avg_price

### Schema Issue (To Be Fixed)
⚠️ `stocks` table has `stock_id` (BIGINT) instead of `stock` (STRING)
- Migration created to fix: `20260119_fix_stocks_table_structure.rb`
- Run: `bundle exec rake db:migrate`

## How to Use

### Start Development Environment

```bash
# Terminal 1: Start Rails
rails server

# Terminal 2: Start Redis (if not running)
redis-server

# Terminal 3: Start Sidekiq with proper queue configuration
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```

### Trigger Daily Bhav Processing

```bash
# Via rake task (recommended)
bundle exec rake bhav:fetch[NSE]

# Via Rails console
rails console
DailyBhavcopyFetcherWorker.perform_async('NSE', Date.today.to_s)

# Watch logs
tail -f log/sidekiq.log
```

### Monitor Progress

Visit: `http://localhost:3000/admin/sidekiq`

Or in Rails console:
```ruby
require 'sidekiq'
Sidekiq::Stats.new.to_h
```

## Expected Log Output

When everything is working:

```
[DailyBhavcopyFetcherWorker] === Starting Daily Bhavcopy Fetch ===
[DailyBhavcopyFetcherWorker] Exchange: NSE, Date: 2025-12-20
[DailyBhavcopyFetcherWorker] Found exchange: National Stock Exchange (NSE)
[DailyBhavcopyFetcherWorker] Fetched 500 rows from ingest service
[DailyBhavcopyFetcherWorker] Mapped 500 rows
[DailyBhavcopyFetcherWorker] Queued slice 1 with 500 rows
[DailyBhavcopyFetcherWorker] === Daily Bhavcopy Fetch Complete ===

[UpsertDailyPricesWorker] === Starting Daily Prices Upsert ===
[UpsertDailyPricesWorker] Processing 500 rows
[UpsertDailyPricesWorker] Successfully upserted: 500, Errors: 0
[UpsertDailyPricesWorker] === Daily Prices Upsert Complete ===
```

## Troubleshooting Checklist

- [ ] Sidekiq running in separate terminal?
- [ ] Redis accessible? (`redis-cli ping` returns PONG)
- [ ] Migration applied? (`bundle exec rake db:migrate`)
- [ ] Exchange exists in database? (`Exchange.find_by(code: 'NSE')`)
- [ ] Logs show worker startup? (`tail -f log/sidekiq.log`)
- [ ] Dashboard shows enqueued jobs? (`http://localhost:3000/admin/sidekiq`)
- [ ] Dead letter queue empty? (No jobs marked as FAILED)

## Next Steps

1. **Implement ExchangeIngestService**
   - Replace stub in `app/services/exchange_ingest_service.rb`
   - Connect to NSE API or CSV endpoint
   - Return proper data format

2. **Apply pending migration**
   ```bash
   bundle exec rake db:migrate
   ```

3. **Test the flow**
   ```bash
   bundle exec rake bhav:fetch[NSE,2025-12-20]
   ```

4. **Setup automatic scheduling (optional)**
   - Add `sidekiq-cron` gem
   - Configure daily fetch schedule
   - Example: 4 PM IST (16:00)

5. **Monitor and alert**
   - Set up alerts for failed jobs
   - Track data freshness
   - Monitor worker health

## Files Modified/Created

**Modified:**
- `app/workers/upsert_daily_prices_worker.rb` - Added logging and error handling
- `app/workers/daily_bhavcopy_fetcher_worker.rb` - Added logging and error handling
- `app/services/bhavcopy_row_mapper.rb` - Removed extras field

**Created:**
- `app/services/exchange_ingest_service.rb` - New service for data fetching
- `lib/tasks/bhav.rake` - Rake tasks for manual triggering
- `db/migrate/20260119_fix_stocks_table_structure.rb` - Schema fix migration
- `DAILY_BHAV_INGESTION.md` - Complete user guide
- `SIDEKIQ_DEBUGGING.md` - Debugging guide

## Testing Checklist

Before deploying to production:

- [ ] Sidekiq worker processes CSV uploads successfully
- [ ] DailyBhavcopyFetcherWorker enqueues UpsertDailyPricesWorker jobs
- [ ] UpsertDailyPricesWorker creates/updates records in daily_prices table
- [ ] Logs show all stages of processing
- [ ] Failed jobs appear in dead letter queue
- [ ] Manual retry of failed jobs works
- [ ] Dashboard displays all information correctly
- [ ] Calculated fields (change_percentage, change_absolute, total_combined_qty_amount) are populated correctly

## Performance Considerations

- **Batch Size:** 500 rows per UpsertDailyPricesWorker job (configurable)
- **Queue Weights:** ingest:5, db_write:3, default:1
- **Concurrency:** 10 threads (-c 10) - adjust based on CPU cores
- **Retry Strategy:** 3 attempts before dead letter queue
- **Redis Memory:** Monitor with `redis-cli INFO memory`

## Support

For debugging:
1. Check logs: `tail -f log/sidekiq.log`
2. View dashboard: `http://localhost:3000/admin/sidekiq`
3. Run: `bundle exec rake bhav:status`
4. Read: `SIDEKIQ_DEBUGGING.md` for detailed troubleshooting
