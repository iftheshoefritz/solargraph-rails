ENV['RAILS_ENV'] = 'test'

require 'solargraph'
require 'solargraph-rails'
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

  config.around(:each) do |example|
    begin
      if key = example.metadata[:coverage]
        Thread.current[:solargraph_arc_coverage] = coverages[key] ||= []
      end

      example.run
    ensure
      Thread.current[:solargraph_arc_coverage] = nil
    end
  end

  config.around(:each, :debug) do |example|
    Solargraph.logger.level = Logger::DEBUG
    example.run
    Solargraph.logger.level = Logger::INFO
  end

  config.after(:suite) do
    if coverages.any?
      coverages.each do |key, data|
        sorted = data.sort_by { |hash| hash[:class_name] }
        File.write("coverage/#{key}.json", JSON.pretty_generate(sorted))
      end
    end
  end

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random
  Kernel.srand config.seed
end
