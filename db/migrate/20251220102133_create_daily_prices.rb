class CreateDailyPrices < ActiveRecord::Migration[8.1]
  def change
    create_table :daily_prices do |t|
      t.references :stock, null: false, foreign_key: true
      t.date :date, null: false
      t.string :series
      t.decimal :prev_day, precision: 15, scale: 4
      t.decimal :open, precision: 15, scale: 4
      t.decimal :low, precision: 15, scale: 4
      t.decimal :high, precision: 15, scale: 4
      t.decimal :close, precision: 15, scale: 4
      t.decimal :last, precision: 15, scale: 4
      t.decimal :avg, precision: 15, scale: 4
      t.bigint  :total_traded
      t.bigint :volume
      t.decimal :turnover, precision: 20, scale: 4
      t.bigint :total_delivered
      t.decimal :deliver_percent, precision: 7, scale: 2
      t.decimal :change_percent, precision: 7, scale: 2
      t.decimal :change_absolute, precision: 15, scale: 4
      t.json :extras
      t.timestamps
    end
    add_index :daily_prices, :date
    add_index :daily_prices, [:stock_id, :date ], unique: true
  end
end
