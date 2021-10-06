# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :admin_users
    resources :users
    resources :organizations
    resources :social_medias, except: :index
    resources :contact_informations
    resources :phone_numbers, except: :index

    root to: 'admin_users#index'
  end

  devise_for :admin_users
  devise_for :users

  resource :home, only: [:index]
  root to: 'home#index'
end
