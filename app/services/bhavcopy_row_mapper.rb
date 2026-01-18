class BhavcopyRowMapper
  def self.map(row)
    prev_close = row['PREV_CLOSE'].to_d
    close_price = row['CLOSE_PRICE'].to_d
    traded_qty = row['TTL_TRD_QNTY'].to_i

    # Calculate change percentage: (close_price - prev_close) / prev_close * 100
    change_percentage = if prev_close.positive?
                          ((close_price - prev_close) / prev_close * 100).round(4)
                        else
                          0
                        end

    # Calculate change absolute amount: close_price - prev_close
    change_absolute = (close_price - prev_close).round(4)

    # Calculate total combined qty * amount: traded_qty * avg_price
    avg_price = row['AVG_PRICE'].to_d
    total_combined_qty_amount = (traded_qty * avg_price).round(4)

    {
      stock: row['SYMBOL'],
      series: row['SERIES'],
      trade_date: Date.parse(row['DATE1']),
      prev_close: prev_close,
      open_price: row['OPEN_PRICE'].to_d,
      high_price: row['HIGH_PRICE'].to_d,
      low_price: row['LOW_PRICE'].to_d,
      last_price: row['LAST_PRICE'].to_d,
      close_price: close_price,
      avg_price: avg_price,
      traded_qty: traded_qty,
      turnover_lacs: row['TURNOVER_LACS'].to_d,
      no_of_trades: row['NO_OF_TRADES'].to_i,
      delivered_qty: row['DELIV_QTY'].to_i,
      delivery_percent: row['DELIV_PER'].to_f,
      change_percentage: change_percentage,
      change_absolute: change_absolute,
      total_combined_qty_amount: total_combined_qty_amount
    }
  end
end

