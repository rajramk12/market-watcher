module Admin
  class SidekiqController < Admin::BaseController
    def index
      @stats = Sidekiq::Stats.new
      @queues = fetch_queues
      @workers = fetch_workers
      @processed_jobs = fetch_processed_jobs
      @failed_jobs = fetch_failed_jobs
    end

    private

    def fetch_queues
      queues = {}
      Sidekiq::Queue.new.each_key do |queue_name|
        queue = Sidekiq::Queue.new(queue_name)
        queues[queue_name] = {
          size: queue.size,
          latency: queue.latency,
          jobs: queue.to_a[0...10] # Get first 10 jobs for preview
        }
      end
      queues
    end

    def fetch_workers
      workers = []
      Sidekiq::Workers.new.each do |worker_id, worker_data|
        workers << {
          id: worker_id,
          queue: worker_data['queue'],
          worker: worker_data['payload']['class'],
          started_at: Time.at(worker_data['run_at']),
          elapsed: (Time.now - Time.at(worker_data['run_at'])).round(2)
        }
      end
      workers
    end

    def fetch_processed_jobs
      Sidekiq.redis do |conn|
        conn.hgetall('stat:processed')
      end
    end

    def fetch_failed_jobs
      failed_set = Sidekiq::SortedSet.new('failed')
      {
        total: failed_set.size,
        sample: failed_set.to_a[0...5]
      }
    end
  end
end
