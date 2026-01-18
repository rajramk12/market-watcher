class FixForeignKeyColumns < ActiveRecord::Migration[8.1]
  def change
    # Step 1: Remove existing invalid foreign keys
    begin
      remove_foreign_key "daily_prices", "stocks" if foreign_key_exists?("daily_prices", "stocks")
    rescue StandardError
      # FK may not exist, continue
    end

    begin
      remove_foreign_key "documents", "stocks" if foreign_key_exists?("documents", "stocks")
    rescue StandardError
      # FK may not exist, continue
    end

    begin
      remove_foreign_key "metrics", "stocks" if foreign_key_exists?("metrics", "stocks")
    rescue StandardError
      # FK may not exist, continue
    end

    # Step 2: Drop existing indexes to prevent conflicts
    begin
      remove_index :daily_prices, name: "index_daily_prices_on_stock_id_and_date"
    rescue StandardError
      # Index may not exist, continue
    end

    begin
      remove_index :documents, name: "index_documents_on_stock_id"
    rescue StandardError
      # Index may not exist, continue
    end

    begin
      remove_index :metrics, name: "index_metrics_on_stock_id"
    rescue StandardError
      # Index may not exist, continue
    end

    # Step 3: Rename columns from stock to stock_id if they're not already renamed
    unless column_exists?(:daily_prices, :stock_id)
      rename_column :daily_prices, :stock, :stock_id if column_exists?(:daily_prices, :stock)
    end

    unless column_exists?(:documents, :stock_id)
      rename_column :documents, :stock, :stock_id if column_exists?(:documents, :stock)
    end

    unless column_exists?(:metrics, :stock_id)
      rename_column :metrics, :stock, :stock_id if column_exists?(:metrics, :stock)
    end

    # Step 4: Ensure columns are proper types
    change_column :daily_prices, :stock_id, :bigint, null: false if column_exists?(:daily_prices, :stock_id)
    change_column :documents, :stock_id, :bigint, null: false if column_exists?(:documents, :stock_id)
    change_column :metrics, :stock_id, :bigint, null: false if column_exists?(:metrics, :stock_id)

    # Step 5: Add indexes
    add_index :daily_prices, [:stock_id, :trade_date], unique: true, if_not_exists: true if column_exists?(:daily_prices, :stock_id)
    add_index :documents, :stock_id, if_not_exists: true if column_exists?(:documents, :stock_id)
    add_index :metrics, :stock_id, if_not_exists: true if column_exists?(:metrics, :stock_id)

    # Step 6: Add foreign key constraints
    add_foreign_key "daily_prices", "stocks", column: "stock_id", if_not_exists: true
    add_foreign_key "documents", "stocks", column: "stock_id", if_not_exists: true
    add_foreign_key "metrics", "stocks", column: "stock_id", if_not_exists: true
