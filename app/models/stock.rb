class Stock < ApplicationRecord
  belongs_to :exchange
  has_many :daily_prices, -> { order(date: :desc) }, dependent: :destroy

  validates :symbol, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :isin, uniqueness: { allow_blank: true, case_sensitive: false }

  scope :by_symbol, ->(symbol) { where(symbol: symbol) }

  def latest_price
    self.daily_prices.order(date: :desc).first
  end

end
