# Load the Rails application.
require_relative 'application'

Rails.application.configure do
  config.eager_load = true
end

# Initialize the Rails application.
Rails.application.initialize!
