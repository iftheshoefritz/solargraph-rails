# Load the Rails application.
require_relative 'application'

Rails.application.configure do
  config.eager_load = true
  config.active_storage.service = :local
end

# Initialize the Rails application.
Rails.application.initialize!
