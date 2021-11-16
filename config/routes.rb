# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias, only: %i[new create edit update]
    resources :services
    resources :categories, only: %i[new create edit update]
    resources :locations, only: %i[show new create edit update]
    resources :location_services
    resources :office_hours
    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users

  resources :locations, only: %i[index new]

  resources :favorite_locations, only: %i[ create destroy ]

  resources :organizations, only: [:show] do
    resources :locations, only: %i[index new create]
  end
  resource :searches, only: %i[new create]

  root to: 'searches#new'
end
