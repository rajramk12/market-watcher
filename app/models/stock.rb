class Stock < ApplicationRecord
  belongs_to :exchange
  has_many :daily_prices

end
