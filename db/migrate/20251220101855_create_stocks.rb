class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.string :stock, null: false
      t.string :name
      t.string :isin
      t.boolean :active
      t.decimal :price, precision: 20, scale: 4
      t.decimal :d1_change, precision: 20, scale: 4
      t.decimal :d1_change_percent, precision: 7, scale: 4
      t.json :mappings
      t.references :exchange, null: false, foreign_key: true
      t.timestamps
    end
    add_index :stocks, [:exchange_id, :stock], unique: true
    add_index :stocks, [:stock], unique: true
    add_index :stocks, [:isin], unique: true
  end
end
