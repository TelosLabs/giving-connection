# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias, only: %i[new create edit update]
    resources :services
    resources :categories, only: %i[new create edit update]
    resources :locations, except: %i[index]
    resources :location_services, only: %i[show create]
    resources :office_hours, except: %i[index]
    resources :messages, only: %i[index show]
    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users

  get '/contact', to: "messages#new", as: :contact
  resources :messages, only: [:create]

  resources :locations, only: %i[index new show]

  resources :organizations, only: [:show] do
    resources :locations, only: %i[index new create]
  end

  resources :organizations, only: %i[edit update]
  resources :favorite_locations, only: %i[ create destroy ]
  resource :searches, only: %i[new create]
  resources :alerts, only: %i[new create delete]
  resource :my_account, only: %i[show]
  root to: 'home#index'
end
