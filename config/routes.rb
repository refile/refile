if PmacsRefile.automount
  Rails.application.routes.draw do
    mount PmacsRefile.app, at: PmacsRefile.mount_point, as: :refile_app
  end
end
