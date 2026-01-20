json.extract! stock, :id, :symbol, :name, :isin, :active, :mappings, :exchange_id, :created_at, :updated_at
json.url stock_url(stock, format: :json)
