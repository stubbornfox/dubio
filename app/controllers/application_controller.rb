class ApplicationController < ActionController::Base
  # http_basic_authenticate_with name: "", password: Rails.application.credentials.HTTP_BASIC_AUTH_PASSWORD, if: -> { ENV['RAILS_ENV'] == 'development' }
end
