# Quick Start - Daily Bhav Processing

## TL;DR - Get It Running in 5 Minutes

### 1. Apply Database Migration
```bash
bundle exec rake db:migrate
```

### 2. Start Services (3 Terminal Windows)

**Terminal 1 - Rails Server**
```bash
rails server
```

**Terminal 2 - Redis**
```bash
redis-server
```

**Terminal 3 - Sidekiq Worker**
```bash
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```

### 3. Trigger Data Processing

**Option A: Via Rake Task**
```bash
bundle exec rake bhav:fetch[NSE]
```

**Option B: Via Rails Console**
```ruby
rails console
DailyBhavcopyFetcherWorker.perform_async('NSE')
```

**Option C: Via CSV Upload**
- Visit: `http://localhost:3000/admin/uploads`
- Upload bhav CSV file
- Processing starts automatically

### 4. Monitor Progress

Visit: `http://localhost:3000/admin/sidekiq`

Or check logs:
```bash
tail -f log/sidekiq.log
```

## What's Working

✅ **CSV File Upload** - Upload bhav files via admin interface
✅ **Job Processing** - Sidekiq queues and processes jobs
✅ **Data Mapping** - BhavcopyRowMapper calculates fields
✅ **Database Writes** - Records stored in daily_prices table
✅ **Comprehensive Logging** - All workers log detailed info
✅ **Error Handling** - Failed jobs visible in dashboard
✅ **Manual Retry** - Failed jobs can be retried

## Calculated Fields

The system automatically calculates:
- `change_percentage` - % change from previous close
- `change_absolute` - absolute price change
- `total_combined_qty_amount` - qty × average price

## Key Logs to Watch

In `log/sidekiq.log`, look for:

```
[DailyBhavcopyFetcherWorker] === Starting Daily Bhavcopy Fetch ===
[DailyBhavcopyFetcherWorker] Fetched 500 rows from ingest service
[UpsertDailyPricesWorker] Successfully upserted: 500, Errors: 0
```

## If Jobs Don't Process

1. **Check Sidekiq is running**
   ```bash
   ps aux | grep sidekiq
   ```

2. **Check Redis**
   ```bash
   redis-cli ping  # Should return PONG
   ```

3. **Check logs**
   ```bash
   tail -f log/sidekiq.log
   tail -f log/development.log | grep -i error
   ```

4. **Check dashboard**
   `http://localhost:3000/admin/sidekiq`
   - Are jobs in "Enqueued" or "Processed"?
   - Are there "Failed" jobs?

5. **Retry failed jobs**
   ```ruby
   rails console
   require 'sidekiq'
   Sidekiq::DeadSet.new.each(&:retry)
   ```

## Common Issues

### "Exchange not found: NSE"
```ruby
rails console
Exchange.create!(code: 'NSE', name: 'National Stock Exchange')
```

### "RecordNotFound: Couldn't find Stock"
CSV data doesn't match expected format. Check:
- SYMBOL column exists
- SERIES, DATE1, prices fields present
- See `DAILY_BHAV_INGESTION.md` for CSV format

### Jobs stuck in queue
```bash
# Kill Sidekiq and restart
pkill -f 'bundle exec sidekiq'
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```

## Files to Know About

- `app/workers/daily_bhavcopy_fetcher_worker.rb` - Fetches market data
- `app/workers/upsert_daily_prices_worker.rb` - Writes to database
- `app/services/exchange_ingest_service.rb` - Data source (stub)
- `app/services/bhavcopy_row_mapper.rb` - Data transformation
- `lib/tasks/bhav.rake` - Rake tasks

## Documentation

- `DAILY_BHAV_INGESTION.md` - Complete guide
- `SIDEKIQ_DEBUGGING.md` - Troubleshooting deep dive
- `DAILY_BHAV_IMPROVEMENTS.md` - What changed

## Next: Implement Real Data Source

The system currently uses a **stub** for `ExchangeIngestService`. To actually fetch data:

1. Edit `app/services/exchange_ingest_service.rb`
2. Implement `fetch_eod(date)` method
3. Connect to NSE API or CSV source
4. Return array of row hashes with fields:
   - SYMBOL, SERIES, DATE1, PREV_CLOSE, OPEN_PRICE, HIGH_PRICE, LOW_PRICE, LAST_PRICE, CLOSE_PRICE, AVG_PRICE, TTL_TRD_QNTY, TURNOVER_LACS, NO_OF_TRADES, DELIV_QTY, DELIV_PER

Example:
```ruby
def fetch_eod(date)
  # Your API/data source here
  # Return: [
  #   {
  #     'SYMBOL' => 'TCS',
  #     'SERIES' => 'EQ',
  #     'DATE1' => '2025-12-20',
  #     'PREV_CLOSE' => '3500.00',
  #     ...
  #   },
  #   ...
  # ]
end
```

## Success Indicators

You'll know it's working when:

1. Dashboard shows increasing "Processed" count
2. Logs show successful upserts
3. `daily_prices` table has new records
4. Calculated fields have non-zero values
5. No failed jobs in dead letter queue

---

**Need help?** Check `SIDEKIQ_DEBUGGING.md` for detailed troubleshooting.
