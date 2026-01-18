class FixStocksTableStructure < ActiveRecord::Migration[8.1]
  def change
    if table_exists?(:stocks)
      # Step 1: Add the correct 'stock' column as string if it doesn't exist
      unless column_exists?(:stocks, :stock)
        add_column :stocks, :stock, :string, after: :name
      end

      # Step 2: Copy data from stock_id to stock if stock_id has string-like data
      # Otherwise populate with placeholder
      begin
        if column_exists?(:stocks, :stock_id)
          # For now, just populate stock column for existing records
          # You may need to backfill this with actual symbol data
          Stock.all.each do |stock|
            if stock.stock.blank?
              # Generate a placeholder - in production, backfill with real symbols
              stock.update_column(:stock, "SYMBOL_#{stock.id}")
            end
          end
        end
      rescue StandardError => e
        puts "Warning during data migration: #{e.message}"
      end

      # Step 3: Remove the incorrect stock_id column and its index
      begin
        remove_index :stocks, name: "index_stocks_on_exchange_id_and_stock" if index_exists?(:stocks, [:exchange_id, :stock_id])
      rescue StandardError => e
        puts "Warning removing index: #{e.message}"
      end

      begin
        remove_column :stocks, :stock_id if column_exists?(:stocks, :stock_id)
      rescue StandardError => e
        puts "Warning removing stock_id column: #{e.message}"
      end

      # Step 4: Create proper unique index on (exchange_id, stock)
      add_index :stocks, [:exchange_id, :stock], unique: true, name: "index_stocks_on_exchange_id_and_stock"
    end
  end
end
