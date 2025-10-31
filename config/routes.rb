Rails.application.routes.draw do
  require "sidekiq/web"
  mount Sidekiq::Web => "/sidekiq"

  namespace :admin do
    resources :admin_users
    resources :users
    resources :social_medias, only: %i[new create edit update]
    resources :services, except: %i[destroy]
    resources :causes, only: %i[new create edit update]
    resources :categories, only: %i[new create edit update]
    resources :locations, except: %i[index]
    resources :location_services, only: %i[show create]
    resources :office_hours, except: %i[index]
    resources :messages, only: %i[index show]
    resources :organization_admins
    resources :phone_numbers, except: %i[index]
    root to: "admin_users#index"
    resources :organizations do
      collection do
        get :upload
        post :import
        get :check_ein
      end
    end
    resource :export_locations, only: :new
    resources :blogs do
      member do
        patch :publish
        patch :unpublish
      end
    end
  end

  devise_for :admin_users
  devise_for :users, controllers: {confirmations: "confirmations"}

  devise_scope :user do
    get "signup" => "devise/registrations#new"
    get "signin" => "devise/sessions#new"
  end

  get "/contact" => "contact_messages#new", :as => :new_contact_message
  post "/contact" => "contact_messages#create", :as => :create_contact_message

  get "/nonprofit" => "nonprofit_requests#new", :as => :new_nonprofit_request
  post "/nonprofit" => "nonprofit_requests#create", :as => :create_nonprofit_request

  get "search" => "searches#show"
  get "termsofuse" => "terms_and_conditions#show", :as => :terms_of_use
  resource :map_popup, only: [:new]
  resource :search_preview, only: [:show]
  resources :search_exports, only: [:create]

  resources :users, only: [:update, :show] do
    resources :blogs, only: [:index], module: :users
  end
  resources :reset_password, only: %i[new]

  resources :locations, only: %i[index new show destroy]

  resources :organizations, only: %i[edit update] do
    get :check_ein, on: :collection
    resources :locations, only: %i[index new create]
    member do
      get "delete_upload/:upload_id", action: :delete_upload
    end
  end

  resources :blogs do
    resources :comments, only: [:create, :edit, :update, :destroy, :show]
    resources :favorite_blogs, only: :create
    resources :blog_likes, only: :create
  end

  resources :favorite_blogs, only: :destroy
  resources :blog_likes, only: :destroy

  resources :favorite_locations, only: %i[create destroy]
  resources :alerts, only: %i[new create edit update destroy]
  resources :causes, param: :name
  get "discover" => "causes#index", :as => :discover
  get "discover/:name" => "causes#show", :as => :discover_show
  resource :my_account, only: %i[show]
  resource :about_us, only: %i[show]
  resource :faqs, only: %i[show]
  resource :donate, only: %i[show]
  resource :privacy_policy, only: %i[show]
  resource :infowindow, only: :new
  resources :autocomplete, only: %i[index]

  root to: "home#index"

  # Custom routes for city-based search
  get "/atlantic-city", to: "cities#show", city: "Atlantic City", as: :atlantic_city
  get "/nashville", to: "cities#show", city: "Nashville", as: :nashville
  get "/los-angeles", to: "cities#show", city: "Los Angeles", as: :los_angeles

  get "redirect", to: "redirection#notice_external_link", as: :redirect
end
