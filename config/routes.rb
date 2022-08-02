# frozen_string_literal: true

Rails.application.routes.draw do
  require 'sidekiq/web'
  mount Sidekiq::Web => '/sidekiq'

  namespace :admin do
    resources :admin_users
    resources :users
    resources :social_medias, only: %i[new create edit update]
    resources :services, only: %i[new create edit update]
    resources :causes, only: %i[new create edit update]
    resources :categories, only: %i[new create edit update]
    resources :locations, except: %i[index]
    resources :location_services, only: %i[show create]
    resources :office_hours, except: %i[index]
    resources :messages, only: %i[index show]
    resources :organization_admins
    resources :phone_numbers, except: %i[index]
    root to: 'admin_users#index'
    resources :organizations do
      collection do
        get :upload
        post :import
      end
    end
  end

  devise_for :admin_users
  devise_for :users

  devise_scope :user do
    get 'signup' => 'devise/registrations#new'
    get 'signin' => 'devise/sessions#new'
  end

  get 'contact' => 'messages#new'
  get '/non-profit', to: 'messages#new', as: :non_profit_contact
  get 'search' => 'searches#show'
  get 'termsofuse' => 'terms_and_conditions#show', as: :terms_of_use

  resources :users, only: [:update]
  resources :messages, only: %i[create]
  resources :reset_password, only: %i[new]

  resources :locations, only: %i[index new show destroy]

  resources :organizations, only: %i[edit update] do
    resources :locations, only: %i[index new create]
  end

  resources :favorite_locations, only: %i[create destroy]
  resources :alerts, only: %i[new create update destroy]
  resource :my_account, only: %i[show]
  resource :about_us, only: %i[show]
  resource :faqs, only: %i[show]
  resource :donate, only: %i[show]
  resource :privacy_policy, only: %i[show]
  root to: 'home#index'
end
