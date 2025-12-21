json.extract! daily_price, :id, :stock, :date, :open, :low, :high, :close, :last, :volume, :turnover, :extras, :created_at, :updated_at
json.url daily_price_url(daily_price, format: :json)
