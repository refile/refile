Rails.application.routes.draw do
  mount Defile.app, at: "attachments", as: :defile_app
end
