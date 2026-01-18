class CsvUploadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ingest

  def perform(file_path)
    exchange = Exchange.find_by_id(1)
    CSV.foreach(file_path, headers: true) do |row|
      mapped = BhavcopyRowMapper.map(row.to_h)
      stock = Stock.find_or_create_by!(stock: mapped[:stock], exchange_id: exchange.id)

      DailyPrice.upsert({
        stock: stock.id,
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
      })
    end
  end
end



