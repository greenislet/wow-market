Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  resources :realms, only: [:index, :show]
  root "home#index"

  get "/data/realms", to: "data#realms"
  # get "/data/items", to: "data#items"
end
