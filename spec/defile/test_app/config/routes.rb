Defile::TestApp.routes.draw do
  root to: "home#index"

  get "/normal/new", to: "normal#new", as: :new_normal
  post "/normal", to: "normal#create", as: :normal
end
