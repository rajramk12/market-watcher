class Stock < ApplicationRecord
  belongs_to :exchange
  has_many :daily_prices, -> { order(date: :desc) }, dependent: :destroy

  scope :latest_price
  scope :by_symbol, ->(symbol) { where(symbol: symbol) }

  def latcest_price
    self.daily_prices.order(date: :desc).first
  end

end
