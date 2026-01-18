# Job Processing Diagnostic Checklist

## Current Status
- ✅ Jobs enqueued correctly
- ❌ Jobs not being processed

## Root Cause
**Sidekiq worker process is not running**

## Fix - Start the required services:

### 1. Verify Redis is Running
```powershell
# Check if Redis service is running
Get-Service Redis -ErrorAction SilentlyContinue
# Or if using WSL
wsl redis-cli ping  # Should return PONG
```

### 2. Start Sidekiq Worker (If using bundler)
```bash
cd c:\Users\rajra\rails_interview\market-watcher
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```

### 3. Verify Jobs Are Processing
Open another terminal:
```bash
cd c:\Users\rajra\rails_interview\market-watcher
rails console

# In Rails console:
require 'sidekiq'
stats = Sidekiq::Stats.new
puts "Processed: #{stats.processed}"
puts "Enqueued: #{stats.enqueued}"
puts "Workers: #{stats.workers_size}"
```

## What Happens When Everything is Running

1. **User uploads CSV** → Admin::UploadsController receives file
2. **Job enqueued** → `CsvUploadWorker.perform_async(file.path)` sends to Redis
3. **Sidekiq worker picks it up** → Takes job from 'ingest' queue
4. **Job executes** → CsvUploadWorker processes CSV, creates stocks, upserts daily_prices
5. **Job completes** → Marked as processed in Sidekiq stats

## Three Terminals Needed

```
Terminal 1: rails server
Terminal 2: bundle exec sidekiq ...  ← THIS WAS MISSING
Terminal 3: tail -f log/sidekiq.log (optional)
```

## Verification Steps

1. Start all 3 services
2. Upload CSV via `http://localhost:3000/admin/uploads`
3. Check logs: `tail -f log/sidekiq.log`
4. View dashboard: `http://localhost:3000/admin/sidekiq`
5. Verify data: `rails console` → `DailyPrice.count`

## Expected Log Output

When everything works:
```
[CsvUploadWorker] === Starting CSV Upload ===
[CsvUploadWorker] File path: /tmp/upload.csv
[CsvUploadWorker] Processed 100 rows...
[CsvUploadWorker] Successfully processed 100 rows, 0 errors
[CsvUploadWorker] === CSV Upload Complete ===
```

---

**TL;DR:** Start Sidekiq in a new terminal:
```bash
bundle exec sidekiq -c 10 -q ingest,5 -q db_write,3 -q default,1 -l log/sidekiq.log
```
