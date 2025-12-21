class UpsertDailyPricesWorker
include Sidekiq::Worker
sidekiq_options queue: :db_write


def perform(rows)
rows.each do |r|
symbol = Symbol.find_or_create_by!(exchange_id: r['exchange_id'], symbol: r['symbol_code'])


DailyPrice.upsert({
symbol_id: symbol.id,
trade_date: r['trade_date'],
series: r['series'],


prev_close: r['prev_close'],
open_price: r['open_price'],
high_price: r['high_price'],
low_price: r['low_price'],
last_price: r['last_price'],
close_price: r['close_price'],
avg_price: r['avg_price'],


total_traded_qty: r['total_traded_qty'],
turnover_lacs: r['turnover_lacs'],
no_of_trades: r['no_of_trades'],


delivered_qty: r['delivered_qty'],
delivered_percent: r['delivered_percent'],


created_at: Time.current,
updated_at: Time.current
}, unique_by: %i[symbol_id trade_date])
end
end
end
