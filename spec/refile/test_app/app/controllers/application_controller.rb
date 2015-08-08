class ApplicationController < ActionController::Base
  def default_url_options(_options = {})
    { locale: I18n.locale }
  end
end
