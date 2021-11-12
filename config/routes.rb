# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias, only: %i[new create edit update]
    resources :services
    resources :categories, only: %i[new create edit update]
    resources :locations
    resources :location_services
    resources :office_hours

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users

  resources :locations, only: %i[index new]

  resources :organizations, only: [:show] do
    resources :locations, only: %i[index new create]
  end
  resource :searches, only: %i[ new ]
  post '/keyword_search', to: "searches#keyword_search", as: :keyword_search
  post '/filter_search', to: "searches#filter_search", as: :filter_search

  root to: 'searches#new'
end
