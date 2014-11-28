Rails.application.routes.draw do
  mount Refile.app, at: "attachments", as: :refile_app
end
