Refile::TestApp.routes.draw do
  root to: "home#index"

  scope path: "normal", as: "normal" do
    resources :posts, controller: "normal_posts"
  end

  scope path: "direct", as: "direct" do
    resources :posts, only: [:new, :create], controller: "direct_posts"
  end

  scope path: "presigned", as: "presigned" do
    resources :posts, only: [:new, :create], controller: "presigned_posts" do
      post :upload, on: :collection
    end
  end
end
