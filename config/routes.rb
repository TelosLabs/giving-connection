Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resource :home, only: [:index]
  root to: 'home#index'
  get '/landing', to: 'landing_page#index'
  get '/contact', to: 'contact#index'
end
