ENV['RAILS_ENV'] = 'test'

require 'bundler/setup'
unless ENV['SIMPLECOV_DISABLED']
  # set up lcov reporting for undercover
  require 'simplecov'
  require 'simplecov-lcov'
  SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
  SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
  SimpleCov.start do
    add_filter(%r{^/spec/})
    add_filter('/Rakefile')
    enable_coverage(:branch)
  end
end

# https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
require 'logger'
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

  # config.order = :random
  Kernel.srand config.seed
end
