namespace :bhav do
  desc "Fetch daily bhavcopy data from NSE for specified exchange"
  task :fetch, [:exchange_code, :date] => :environment do |t, args|
    require 'sidekiq'

    exchange_code = args[:exchange_code] || ENV['EXCHANGE_CODE'] || 'NSE'
    date_str = args[:date] || ENV['FETCH_DATE'] || Date.today.to_s

    puts "Fetching bhav data for #{exchange_code} on #{date_str}..."

    begin
      DailyBhavcopyFetcherWorker.perform_async(exchange_code, date_str)
      puts "✓ Job enqueued successfully (exchange: #{exchange_code}, date: #{date_str})"

      # Show queue status
      stats = Sidekiq::Stats.new
      puts "\nQueue Status:"
      puts "  Ingest queue size: #{stats.processed_size} processed, #{stats.enqueued} enqueued"
      puts "  Workers: #{stats.workers_size} active"
    rescue StandardError => e
      puts "✗ Error enqueueing job: #{e.message}"
      exit 1
    end
  end

  desc "Fetch daily bhavcopy data for multiple exchanges"
  task :fetch_all, [:date] => :environment do |t, args|
    require 'sidekiq'

    date_str = args[:date] || ENV['FETCH_DATE'] || Date.today.to_s

    puts "Fetching bhav data for all exchanges on #{date_str}..."

    exchanges = Exchange.where(active: true).pluck(:code)

    if exchanges.empty?
      puts "No active exchanges found"
      next
    end

    puts "Found #{exchanges.size} active exchange(s): #{exchanges.join(', ')}"

    exchanges.each do |code|
      begin
        DailyBhavcopyFetcherWorker.perform_async(code, date_str)
        puts "✓ Enqueued #{code}"
      rescue StandardError => e
        puts "✗ Failed to enqueue #{code}: #{e.message}"
      end
    end

    stats = Sidekiq::Stats.new
    puts "\nTotal jobs enqueued: #{stats.enqueued}"
  end

  desc "Check the status of bhav fetch jobs in Sidekiq"
  task :status => :environment do
    require 'sidekiq'

    stats = Sidekiq::Stats.new

    puts "=== Sidekiq Job Status ==="
    puts "Processed: #{stats.processed}"
    puts "Failed: #{stats.failed}"
    puts "Enqueued: #{stats.enqueued}"
    puts "Workers: #{stats.workers_size} active"
    puts "Processes: #{stats.processes_size}"

    # Show ingest queue details
    queue = Sidekiq::Queue.new('ingest')
    puts "\nIngest Queue:"
    puts "  Size: #{queue.size}"
    puts "  Latency: #{queue.latency}s"

    if queue.size > 0
      puts "\n  First 5 jobs:"
      queue.each_with_index do |job, idx|
        break if idx >= 5
        puts "    #{idx + 1}. #{job['class']} - #{job['created_at']}"
      end
    end

    # Show dead letter queue
    dead_letter_queue = Sidekiq::Queue.new('dead')
    if dead_letter_queue.size > 0
      puts "\nDead Letter Queue: #{dead_letter_queue.size} jobs"
      puts "  First job: #{dead_letter_queue.first['class']}"
    end
  end
end
