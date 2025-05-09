ENV['RAILS_ENV'] = 'test'

require 'debug'
require 'solargraph'
require 'solargraph-rails'
require 'logger'
require 'debug'
require 'fileutils'
require_relative './helpers'

RSpec.configure do |config|
  coverages = {}

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.include(Helpers)
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = 'tmp/examples.txt'
  config.disable_monkey_patching!

  config.before(:suite) do
    # NOTE: without this, gem logic does not see gems inside sample project"
    Bundler.reset_rubygems!
  end

  config.around(:each, :debug) do |example|
    Solargraph.logger.level = Logger::DEBUG
    example.run
    Solargraph.logger.level = Logger::INFO
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
