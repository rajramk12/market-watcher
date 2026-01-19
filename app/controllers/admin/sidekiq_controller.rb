module Admin
  class SidekiqController < Admin::BaseController
    def index
      @stats = Sidekiq::Stats.new
      @queues = fetch_queues
      @workers = fetch_workers
      @processed_jobs = fetch_processed_jobs
      @failed_jobs = fetch_failed_jobs
      @dead_letter = fetch_dead_letter_jobs
      @redis_info = fetch_redis_info
    end

    def clear_queue
      queue_name = params[:queue]
      queue = Sidekiq::Queue.new(queue_name)
      count = queue.size
      queue.clear

      redirect_to admin_sidekiq_path, notice: "Queue '#{queue_name}' cleared. #{count} jobs removed."
    end

    def retry_failed
      failed_set = Sidekiq::SortedSet.new('failed')
      count = failed_set.size
      failed_set.each { |job| job.retry }

      redirect_to admin_sidekiq_path, notice: "#{count} failed jobs have been retried."
    end

    def clear_failed
      failed_set = Sidekiq::SortedSet.new('failed')
      count = failed_set.size
      failed_set.clear

      redirect_to admin_sidekiq_path, notice: "All #{count} failed jobs have been cleared."
    end

    private

    def fetch_queues
      queues = {}
      Sidekiq::Queue.all.each do |queue|
        queue_name = queue.name
        queues[queue_name] = {
          size: queue.size,
          latency: queue.latency,
          jobs: queue.to_a[0...10]
        }
      end
      queues
    end

    def fetch_workers
      workers = []
      Sidekiq::Workers.new.each do |worker_id, worker_data|
        begin
          workers << {
            id: worker_id,
            queue: worker_data['queue'],
            worker: worker_data['payload']['class'],
            started_at: Time.at(worker_data['run_at']),
            elapsed: (Time.now - Time.at(worker_data['run_at'])).round(2),
            args: worker_data['payload']['args'].inspect
          }
        rescue StandardError => e
          Rails.logger.error "Error fetching worker data: #{e.message}"
        end
      end
      workers
    end

    def fetch_processed_jobs
      Sidekiq.redis do |conn|
        {
          processed: conn.get('stat:processed').to_i,
          failed: conn.get('stat:failed').to_i
        }
      end
    end

    def fetch_failed_jobs
      failed_set = Sidekiq::SortedSet.new('failed')
      {
        total: failed_set.size,
        sample: failed_set.to_a[0...5]
      }
    end

    def fetch_dead_letter_jobs
      dead_set = Sidekiq::SortedSet.new('dead')
      {
        total: dead_set.size,
        sample: dead_set.to_a[0...3]
      }
    end

    def fetch_redis_info
      Sidekiq.redis do |conn|
        info = conn.info('stats')
        {
          connected: true,
          total_connections_received: info['total_connections_received'].to_i,
          total_commands_processed: info['total_commands_processed'].to_i,
          used_memory_human: info['used_memory_human'] || 'N/A'
        }
      rescue StandardError => e
        {
          connected: false,
          error: e.message
        }
      end
    end
  end
end
