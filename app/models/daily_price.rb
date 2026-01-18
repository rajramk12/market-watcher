class DailyPrice < ApplicationRecord
  belongs_to :stock

  validates :trade_date, presence: true
end
