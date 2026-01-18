class ExchangeIngestService
  def initialize(exchange)
    @exchange = exchange
  end

  # Fetches end-of-day (EOD) data for the given date
  # This is a stub implementation - replace with actual API call or data source
  def fetch_eod(date)
    logger.info "Fetching EOD data for exchange: #{@exchange.code}, date: #{date}"

    # Stub: Returns empty array
    # In production, this would:
    # 1. Call NSE API or fetch from CSV endpoint
    # 2. Return array of row hashes with keys: SYMBOL, PREV_CLOSE, OPEN_PRICE, HIGH, LOW, CLOSE, etc.

    logger.info "No data fetched for date #{date} (stub implementation)"
    []
  end

  private

  def logger
    Rails.logger
  end
end
