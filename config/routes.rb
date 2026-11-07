Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "docs" => redirect("/docs/index.html")

  # Read-only Active Storage routes for cover image URLs (draw_routes is off in config/application.rb).
  scope ActiveStorage.routes_prefix do
    get "/blobs/redirect/:signed_id/*filename" => "active_storage/blobs/redirect#show", as: :rails_service_blob
    get "/disk/:encoded_key/*filename" => "active_storage/disk#show", as: :rails_disk_service
  end

  direct :rails_blob do |blob, options|
    expires_in = options.delete(:expires_in) { ActiveStorage.urls_expire_in }

    route_for(:rails_service_blob, blob.signed_id(expires_in:), blob.filename, options)
  end

  namespace :api do
    namespace :v1 do
      resources :projects, only: %i[index show create update destroy] do
        resource :favorite, only: %i[create destroy], module: :project
      end

      namespace :user do
        resource :registrations, only: %i[create]
        resource :authentications, only: %i[create]
        resource :accounts, only: %i[destroy]
        resource :profiles, only: %i[update]

        namespace :email do
          resource :confirmations, only: %i[create]
          resource :changes, only: %i[update]
        end

        namespace :password do
          resource :changes, only: %i[update]
          resource :resets, only: %i[create update]
        end

        namespace :session do
          resource :refreshes, only: %i[update]
          resource :revokes, only: %i[destroy]
        end
      end
    end
  end
end
