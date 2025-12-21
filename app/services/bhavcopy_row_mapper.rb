class BhavcopyRowMapper
def self.map(row)
{
symbol_code: row['SYMBOL'],
series: row['SERIES'],
trade_date: Date.parse(row['DATE1']),


prev_close: row['PREV_CLOSE'].to_d,
open_price: row['OPEN_PRICE'].to_d,
high_price: row['HIGH_PRICE'].to_d,
low_price: row['LOW_PRICE'].to_d,
last_price: row['LAST_PRICE'].to_d,
close_price: row['CLOSE_PRICE'].to_d,
avg_price: row['AVG_PRICE'].to_d,


total_traded_qty: row['TTL_TRD_QNTY'].to_i,
turnover_lacs: row['TURNOVER_LACS'].to_d,
no_of_trades: row['NO_OF_TRADES'].to_i,


delivered_qty: row['DELIV_QTY'].to_i,
delivered_percent: row['DELIV_PER'].to_d
}
end
end
