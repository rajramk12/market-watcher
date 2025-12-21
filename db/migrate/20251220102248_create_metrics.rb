class CreateMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :metrics do |t|
      t.date :date, null: false
      t.decimal :pe, precision: 15, scale: 4
      t.decimal :pb, precision: 15, scale: 4
      t.decimal :mcap, precision:20, scale: 4
      t.json :fundamentals
      t.references :stock, null: false, foreign_key: true

      t.timestamps
    end
  end
end
