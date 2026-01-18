Rails.application.routes.draw do
  require 'sidekiq/web'

  resources :documents, only: [:show]
  resources :metrics, only: [:show]
  resources :daily_prices, only: [:index]
  resources :stocks, only: [:index, :show]
  resources :exchanges, only: [:index, :show]

  root "stocks#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    resources :uploads, only: [:new, :create]

    # Sidekiq monitoring
    get 'sidekiq', to: 'sidekiq#index', as: 'sidekiq'
    post 'sidekiq/clear_queue', to: 'sidekiq#clear_queue', as: 'clear_queue'
    post 'sidekiq/retry_failed', to: 'sidekiq#retry_failed', as: 'retry_failed'
    post 'sidekiq/clear_failed', to: 'sidekiq#clear_failed', as: 'clear_failed'
    mount Sidekiq::Web => '/sidekiq/dashboard'
  end
end
