require "test_helper"

class DailyPricesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @daily_price = daily_prices(:one)
  end

  test "should get index" do
    get daily_prices_url
    assert_response :success
  end

  test "should get new" do
    get new_daily_price_url
    assert_response :success
  end

  test "should create daily_price" do
    assert_difference("DailyPrice.count") do
      post daily_prices_url, params: { daily_price: { close: @daily_price.close, date: @daily_price.date, extras: @daily_price.extras, high: @daily_price.high, last: @daily_price.last, low: @daily_price.low, open: @daily_price.open, stock: @daily_price.stock, turnover: @daily_price.turnover, volume: @daily_price.volume } }
    end

    assert_redirected_to daily_price_url(DailyPrice.last)
  end

  test "should show daily_price" do
    get daily_price_url(@daily_price)
    assert_response :success
  end

  test "should get edit" do
    get edit_daily_price_url(@daily_price)
    assert_response :success
  end

  test "should update daily_price" do
    patch daily_price_url(@daily_price), params: { daily_price: { close: @daily_price.close, date: @daily_price.date, extras: @daily_price.extras, high: @daily_price.high, last: @daily_price.last, low: @daily_price.low, open: @daily_price.open, stock: @daily_price.stock, turnover: @daily_price.turnover, volume: @daily_price.volume } }
    assert_redirected_to daily_price_url(@daily_price)
  end

  test "should destroy daily_price" do
    assert_difference("DailyPrice.count", -1) do
      delete daily_price_url(@daily_price)
    end

    assert_redirected_to daily_prices_url
  end
end
