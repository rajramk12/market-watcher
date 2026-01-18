class DailyBhavcopyFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ingest, retry: 3

  def perform(exchange_code, date_str = Date.today.to_s)
    logger.info "=== Starting Daily Bhavcopy Fetch ==="
    logger.info "Exchange: #{exchange_code}, Date: #{date_str}"

    begin
      # Fetch and validate exchange
      exchange = Exchange.find_by!(code: exchange_code)
      logger.info "Found exchange: #{exchange.name} (#{exchange.code})"

      date = Date.parse(date_str)
      logger.info "Processing date: #{date}"

      # Fetch data from ingest service
      begin
        rows = ExchangeIngestService.new(exchange).fetch_eod(date)
        logger.info "Fetched #{rows.size} rows from ingest service"
      rescue StandardError => e
        logger.error "Failed to fetch data from ExchangeIngestService: #{e.message}"
        logger.error e.backtrace.join("\n")
        raise "Data fetch failed: #{e.message}"
      end

      if rows.empty?
        logger.warn "No data received for #{exchange_code} on #{date}"
        return
      end

      # Map and enqueue for database writes
      begin
        mapped = rows.map do |r|
          BhavcopyRowMapper.map(r).merge('exchange_id' => exchange.id)
        end
        logger.info "Mapped #{mapped.size} rows"

        slice_count = 0
        mapped.each_slice(500) do |slice|
          UpsertDailyPricesWorker.perform_async(slice)
          slice_count += 1
          logger.info "Queued slice #{slice_count} with #{slice.size} rows"
        end

        logger.info "=== Daily Bhavcopy Fetch Complete ==="
        logger.info "Enqueued #{slice_count} slices for database write"
      rescue StandardError => e
        logger.error "Failed to map or enqueue rows: #{e.message}"
        logger.error e.backtrace.join("\n")
        raise
      end
    rescue Exchange::RecordNotFound => e
      logger.error "Exchange not found: #{exchange_code}"
      logger.error e.backtrace.join("\n")
      raise "Exchange #{exchange_code} not found"
    rescue Date::Error => e
      logger.error "Invalid date format: #{date_str}"
      logger.error e.backtrace.join("\n")
      raise "Invalid date: #{date_str}"
    rescue StandardError => e
      logger.error "Daily Bhavcopy Fetch Failed: #{e.message}"
      logger.error e.backtrace.join("\n")
      raise
    end
  end
end
