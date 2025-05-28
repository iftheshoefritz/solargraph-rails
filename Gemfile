source 'https://rubygems.org'

group :development, :test do
  gem 'bundler-audit'
  gem 'debug'
  gem 'byebug'
end

rails_version = ENV['MATRIX_RAILS_VERSION'] || '7'
if rails_version == '7'
  # https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
  gem "concurrent-ruby", '<=1.3.5'
end

# Specify your gem's dependencies in solargraph_rails.gemspec
gemspec

solargraph_force_ci_version = (ENV['CI'] && ENV['MATRIX_SOLARGRAPH_VERSION'])

if solargraph_force_ci_version == '0.54.6.alpha'
  gem 'solargraph',
      github: 'apiology/solargraph',
      branch: 'v54-alpha'
    # path: '../solargraph'
end

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
