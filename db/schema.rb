# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_12_20_102328) do
  create_table "daily_prices", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.date "trade_date", null: false
    t.bigint "symbol", null: false
    t.decimal "avg_price", precision: 15, scale: 4
    t.decimal "close_price", precision: 15, scale: 4
    t.datetime "created_at", null: false
    t.bigint "delivered_qty"
    t.decimal "delivery_percent", precision: 7, scale: 4
    t.json "extras"
    t.decimal "high_price", precision: 15, scale: 4
    t.decimal "last_price", precision: 15, scale: 4
    t.decimal "low_price", precision: 15, scale: 4
    t.bigint "no_of_trades"
    t.decimal "open_price", precision: 15, scale: 4
    t.decimal "prev_close", precision: 15, scale: 4
    t.string "series"
    t.bigint "traded_qty"
    t.decimal "turnover_lacs", precision: 20, scale: 4
    t.datetime "updated_at", null: false
    t.index ["symbol", "trade_date"], name: "index_daily_prices_on_stock_id_and_date", unique: true
    t.index ["trade_date"], name: "index_daily_prices_on_date", unique: false
  end

  create_table "documents", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "doc_type"
    t.json "metadata"
    t.string "s3_key"
    t.string "symbol", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_documents_on_stock_id"
  end

  create_table "exchanges", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.json "metadata"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_exchanges_on_code", unique: true
  end

  create_table "metrics", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.json "fundamentals"
    t.decimal "mcap", precision: 20, scale: 4
    t.decimal "pb", precision: 15, scale: 4
    t.decimal "pe", precision: 15, scale: 4
    t.string "symbol", null: false
    t.datetime "updated_at", null: false
    t.index ["symbol"], name: "index_metrics_on_stock_id"
  end

  create_table "stocks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "symbol", null: false
    t.boolean "active"
    t.datetime "created_at", null: false
    t.bigint "exchange_id", null: false
    t.string "isin"
    t.json "mappings"
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["exchange_id", "symbol"], name: "index_stocks_on_exchange_id_and_stock", unique: true
    t.index ["exchange_id"], name: "index_stocks_on_exchange_id"
  end

  add_foreign_key "daily_prices", "stocks", column: "symbol"
  add_foreign_key "documents", "stocks", column: "symbol"
  add_foreign_key "metrics", "stocks", column: "symbol"
  add_foreign_key "stocks", "exchanges", column: "symbol"
end
