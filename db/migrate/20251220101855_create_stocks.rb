class CreateStocks < ActiveRecord::Migration[8.1]
  def change
    create_table :stocks do |t|
      t.string :stock, null: false
      t.string :name
      t.string :isin
      t.boolean :active
      t.precision :15, scale: 4 :price
      t.precision :15, scale: 4 :d1_change
      t.percentage :7, scale: 2 :d1_change_percent
      t.json :mappings
      t.references :exchange, null: false, foreign_key: true
      t.timestamps
    end
    add_index :stocks, [:exchange_id, :stock], unique: true
    add_index :stocks, [:stock], unique: true
    add_index :stocks, [:isin], unique: true
  end
end
