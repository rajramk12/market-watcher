class DailyPrice < ApplicationRecord
  belongs_to :stock

  validates :date, presence: true 
end
