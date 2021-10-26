# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias
    resources :locations

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users

  resources :organizations, only: [:show] do
    resources :locations, only: %i[index new create]
  end
  resource :searches, only: %i[new create]

  root to: 'searches#new'
end
