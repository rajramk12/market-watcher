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
          stock = Stock.find_or_create_by!(stock: mapped[:stock], exchange_id: exchange.id)

          DailyPrice.upsert({
            stock_id: stock.id,
            trade_date: mapped[:trade_date],
            series: mapped[:series],
            prev_close: mapped[:prev_close],
            open_price: mapped[:open_price],
            high_price: mapped[:high_price],
            low_price: mapped[:low_price],
            last_price: mapped[:last_price],
            close_price: mapped[:close_price],
            avg_price: mapped[:avg_price],
            traded_qty: mapped[:traded_qty],
            turnover_lacs: mapped[:turnover_lacs],
            no_of_trades: mapped[:no_of_trades],
            delivered_qty: mapped[:delivered_qty],
            delivery_percent: mapped[:delivery_percent],
            change_percentage: mapped[:change_percentage],
            change_absolute: mapped[:change_absolute],
            total_combined_qty_amount: mapped[:total_combined_qty_amount],
            created_at: Time.current,
            updated_at: Time.current
          }, unique_by: [:stock_id, :trade_date])
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




