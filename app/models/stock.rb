class Stock < ApplicationRecord
  belongs_to :exchange
  has_many :daily_prices, -> { order(trade_date: :desc) }, dependent: :destroy

  validates :stock, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :isin, uniqueness: { allow_blank: true, case_sensitive: false }

  scope :by_stock, ->(stock) { where(stock: stock) }

  def latest_price
    daily_prices.first
  end
end
