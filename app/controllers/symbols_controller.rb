class SymbolsController < ApplicationController
def index
if params[:q].present?
@symbols = Symbol.search(params[:q], fields: [:symbol, :name], match: :word_start)
else
@symbols = Symbol.all.limit(50)
end
end


def show
@symbol = Symbol.find(params[:id])
@prices = @symbol.daily_prices.order(trade_date: :desc).limit(200)
end
end
