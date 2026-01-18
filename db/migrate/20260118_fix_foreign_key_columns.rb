class FixForeignKeyColumns < ActiveRecord::Migration[8.1]
  def change
    # Remove existing foreign keys
    remove_foreign_key "daily_prices", "stocks"
    remove_foreign_key "documents", "stocks"
    remove_foreign_key "metrics", "stocks"

    # For daily_prices: rename stock (string) to stock_id (bigint)
    remove_index :daily_prices, name: "index_daily_prices_on_stock_id_and_date"
    remove_index :daily_prices, [:stock, :trade_date]
    rename_column :daily_prices, :stock, :stock_id
    change_column :daily_prices, :stock_id, :bigint
    add_index :daily_prices, [:stock_id, :trade_date], unique: true

    # For documents: ensure stock is stock_id and is properly typed
    remove_index :documents, name: "index_documents_on_stock_id"
    rename_column :documents, :stock, :stock_id
    add_index :documents, :stock_id

    # For metrics: ensure stock is stock_id
    remove_index :metrics, name: "index_metrics_on_stock_id"
    rename_column :metrics, :stock, :stock_id
    add_index :metrics, :stock_id

    # Re-add foreign keys with correct column names
    add_foreign_key "daily_prices", "stocks", column: "stock_id"
    add_foreign_key "documents", "stocks", column: "stock_id"
    add_foreign_key "metrics", "stocks", column: "stock_id"
  end
end
