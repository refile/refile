Rails.application.routes.draw do
  get "/attachment/:backend_name(/:width/:height(/:crop))/:id(.:format)", as: :attachment_route, to: "attachments#show"
end
