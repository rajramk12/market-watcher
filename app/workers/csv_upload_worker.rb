class CsvUploadWorker
include Sidekiq::Worker
sidekiq_options queue: :ingest


def perform(file_path)
CSV.foreach(file_path, headers: true) do |row|
  debugger
  mapped = BhavcopyRowMapper.map(row.to_h)
  symbol = Symbol.find_or_create_by!(symbol: mapped[:symbol_code])


DailyPrice.upsert({
symbol_id: symbol.id,
trade_date: mapped[:trade_date],
series: mapped[:series],
prev_close: mapped[:prev_close],
open_price: mapped[:open_price],
high_price: mapped[:high_price],
low_price: mapped[:low_price],
last_price: mapped[:last_price],
close_price: mapped[:close_price],
avg_price: mapped[:avg_price],
total_traded_qty: mapped[:total_traded_qty],
turnover_lacs: mapped[:turnover_lacs],
no_of_trades: mapped[:no_of_trades],
delivered_qty: mapped[:delivered_qty],
delivered_percent: mapped[:delivered_percent],
created_at: Time.current,
updated_at: Time.current
}, unique_by: %i[symbol_id trade_date])
end
end
end
