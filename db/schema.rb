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
    t.decimal "avg", precision: 15, scale: 4
    t.decimal "close", precision: 15, scale: 4
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.decimal "deliver_percent", precision: 7, scale: 2
    t.json "extras"
    t.decimal "high", precision: 15, scale: 4
    t.decimal "last", precision: 15, scale: 4
    t.decimal "low", precision: 15, scale: 4
    t.decimal "open", precision: 15, scale: 4
    t.decimal "prev_day", precision: 10
    t.string "series"
    t.bigint "stock_id", null: false
    t.bigint "total_delivered"
    t.bigint "total_traded"
    t.decimal "turnover", precision: 20, scale: 4
    t.datetime "updated_at", null: false
    t.bigint "volume"
    t.index ["date"], name: "index_daily_prices_on_date"
    t.index ["stock_id", "date"], name: "index_daily_prices_on_stock_id_and_date", unique: true
    t.index ["stock_id"], name: "index_daily_prices_on_stock_id"
  end

  create_table "documents", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "doc_type"
    t.json "metadata"
    t.string "s3_key"
    t.bigint "stock_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_documents_on_stock_id"
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
    t.bigint "stock_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stock_id"], name: "index_metrics_on_stock_id"
  end

  create_table "stocks", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "active"
    t.datetime "created_at", null: false
    t.bigint "exchange_id", null: false
    t.string "isin"
    t.json "mappings"
    t.string "name"
    t.string "stock"
    t.datetime "updated_at", null: false
    t.index ["exchange_id", "stock"], name: "index_stocks_on_exchange_id_and_stock", unique: true
    t.index ["exchange_id"], name: "index_stocks_on_exchange_id"
  end

  add_foreign_key "daily_prices", "stocks"
  add_foreign_key "documents", "stocks"
  add_foreign_key "metrics", "stocks"
  add_foreign_key "stocks", "exchanges"
end
