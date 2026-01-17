class AddCalculatedFieldsToDailyPrices < ActiveRecord::Migration[8.1]
  def change
    # Change percentage: (close_price - prev_close) / prev_close * 100
    add_column :daily_prices, :change_percentage, :decimal, precision: 10, scale: 4, default: 0

    # Change absolute amount: close_price - prev_close
    add_column :daily_prices, :change_absolute, :decimal, precision: 15, scale: 4, default: 0

    # Total combined qty * amount traded (quantity * price)
    add_column :daily_prices, :total_combined_qty_amount, :decimal, precision: 20, scale: 4, default: 0

    # Add indexes for faster queries
    add_index :daily_prices, :change_percentage
    add_index :daily_prices, :change_absolute
  end
end
