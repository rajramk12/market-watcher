class DailyBhavcopyFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :ingest

  def perform(exchange_code, date_str = Date.today.to_s)
    exchange = Exchange.find_by!(code: exchange_code)
    date = Date.parse(date_str)

    rows = ExchangeIngestService.new(exchange).fetch_eod(date)
    mapped = rows.map { |r| BhavcopyRowMapper.map(r).merge('exchange_id' => exchange.id) }

    mapped.each_slice(500) do |slice|
      UpsertDailyPricesWorker.perform_async(slice)
    end
  end
end
