class CsvUploadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ingest, retry: 3

  def perform(file_path)
    logger.info "=== Starting CSV Upload ==="
    logger.info "File path: #{file_path}"
    logger.info "File exists: #{File.exist?(file_path)}"

    raise "File not found: #{file_path}" unless File.exist?(file_path)

    exchange = Exchange.find_by_id(1)
    raise "Exchange not found" unless exchange

    row_count = 0
    error_count = 0

    begin
      CSV.foreach(file_path, headers: true) do |row|
        row_count += 1
        begin
          mapped = BhavcopyRowMapper.map(row.to_h)
          stock = Stock.upsert(symbol: mapped[:symbol], exchange_id: exchange.id ,name: mapped[:name], price: mapped[:last_price], isin: mapped[:isin], active: true,d1_change: mapped[:change_absolute], d1_change_percent: mapped[:change_percentage])

          DailyPrice.upsert({
            symbol: stock.symbol,
            date: mapped[:trade_date],
            series: mapped[:series],
            prev_day: mapped[:prev_close],
            open: mapped[:open_price],
            high: mapped[:high_price],
            low: mapped[:low_price],
            last: mapped[:last_price],
            close: mapped[:close_price],
            avg: mapped[:avg_price],
            total_traded: mapped[:traded_qty],
            turnover: mapped[:turnover_lacs],
            volume: mapped[:no_of_trades],
            total_delivered: mapped[:delivered_qty],
            deliver_percent: mapped[:delivery_percent],
            change_percent: mapped[:change_percentage],
            change_absolute: mapped[:change_absolute],
            created_at: Time.current,
            updated_at: Time.current
          }, unique_by: [:stock, :date])
        rescue StandardError => e
          error_count += 1
          logger.error "Error processing row #{row_count}: #{e.message}"
          logger.error e.backtrace.join("\n")
        end

        logger.info "Processed #{row_count} rows..." if row_count % 100 == 0
      end

      logger.info "=== CSV Upload Complete ==="
      logger.info "Total rows: #{row_count}, Errors: #{error_count}"
    rescue StandardError => e
      logger.error "CSV Upload Failed: #{e.message}"
      logger.error e.backtrace.join("\n")
      raise
    ensure
      # Clean up file after processing (success or failure)
      if File.exist?(file_path)
        File.delete(file_path)
        logger.info "Cleaned up file: #{file_path}"
      end
    end
  end
end




