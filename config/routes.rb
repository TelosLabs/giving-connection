# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  resources :organizations, only: [:show] do
    resource :locations, only: %i[index new create]
  end
  resource :searches, only: %i[new create]

  root to: 'locations#index'
end
