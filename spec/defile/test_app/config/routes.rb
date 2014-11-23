Defile::TestApp.routes.draw do
  root to: "home#index"

  scope path: "normal", as: "normal" do
    resources :posts, only: [:new, :create, :show], controller: "normal_posts"
  end
end
