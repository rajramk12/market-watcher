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
    get 'sidekiq', to: 'sidekiq#index'
    mount Sidekiq::Web => '/sidekiq/dashboard'
  end
end
