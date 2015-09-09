Refile::TestApp.routes.draw do
  root to: "home#index"

  scope path: "normal", as: "normal" do
    resources :posts, controller: "normal_posts"
  end

  scope path: "multiple", as: "multiple" do
    resources :posts, controller: "multiple_posts"
  end

  scope path: "direct", as: "direct" do
    resources :posts, only: [:new, :create], controller: "direct_posts"
  end

  scope path: "presigned", as: "presigned" do
    resources :posts, only: [:new, :create], controller: "presigned_posts" do
      post :upload, on: :collection
    end
  end

  scope path: "simple_form", as: "simple_form" do
    resources :posts, only: [:new, :create], controller: "simple_form_posts"
  end
end
