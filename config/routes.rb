Rails.application.routes.draw do
  root "posts#index"

  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  get "/logout", to: "sessions#destroy"

  resources :posts do
    resources :comments, only: [ :create ]
  end
end
