source 'https://rubygems.org'


rails_version = ENV['MATRIX_RAILS_VERSION'] || '7'

if rails_version == '7'
  # https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
  gem "concurrent-ruby", '<=1.3.5'
end

group :development, :test do
  gem 'bundler-audit'
  gem 'debug'
  gem 'byebug'
end

# Specify your gem's dependencies in solargraph_rails.gemspec
gemspec

gem 'solargraph',
    github: 'apiology/solargraph',
    branch: '2025-04-28'
    # path: '../solargraph'
