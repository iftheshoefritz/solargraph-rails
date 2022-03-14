require_relative 'boot'
require 'rails/all'

Bundler.require(*Rails.groups)

module MyApp
  class Application < Rails::Application
    ##
  end
end
