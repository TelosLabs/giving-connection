Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resource :locations, only: [:index, :new, :create]
  resource :searches, only: [:new, :create]

  get '/locations', to: 'locations#index' # TODO remove
  root to: 'locations#index'
end
