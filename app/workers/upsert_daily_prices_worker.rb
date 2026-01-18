class UpsertDailyPricesWorker
  include Sidekiq::Worker
  sidekiq_options queue: :db_write

  def perform(rows)
    rows.each do |r|
      stock = Stock.find_or_create_by!(exchange_id: r['exchange_id'], stock: r['stock'])

      DailyPrice.upsert({
        stock_id: stock.id,
        trade_date: r['trade_date'],
        series: r['series'],
        prev_close: r['prev_close'],
        open_price: r['open_price'],
        high_price: r['high_price'],
        low_price: r['low_price'],
        last_price: r['last_price'],
        close_price: r['close_price'],
        avg_price: r['avg_price'],
        traded_qty: r['traded_qty'],
        turnover_lacs: r['turnover_lacs'],
        no_of_trades: r['no_of_trades'],
        delivered_qty: r['delivered_qty'],
        delivery_percent: r['delivery_percent'],
        change_percentage: r['change_percentage'],
        change_absolute: r['change_absolute'],
        total_combined_qty_amount: r['total_combined_qty_amount'],
        created_at: Time.current,
        updated_at: Time.current
      }, unique_by: %i[stock trade_date])
    end
  end
end
