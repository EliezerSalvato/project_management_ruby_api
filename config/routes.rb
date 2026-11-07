Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "docs" => redirect("/docs/index.html")

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
