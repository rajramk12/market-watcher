# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed Exchanges
exchanges = [
  { code: 'NSE', name: 'National Stock Exchange of India' },
  { code: 'BSE', name: 'Bombay Stock Exchange' }
]

exchanges.each do |exchange_attrs|
  Exchange.find_or_create_by!(code: exchange_attrs[:code]) do |exchange|
    exchange.name = exchange_attrs[:name]
  end
end

puts "✓ Seeded #{exchanges.size} exchanges"
