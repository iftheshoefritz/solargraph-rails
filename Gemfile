source 'https://rubygems.org'


rails_version = ENV['MATRIX_RAILS_VERSION'] || '7'
instance_eval File.read(File.expand_path("spec/rails#{rails_version}/Gemfile", __dir__))

group :development, :test do
  gem 'bundler-audit'
  gem 'debug'
  gem 'byebug'
end

if rails_version == '7'
  # https://stackoverflow.com/questions/79360526/uninitialized-constant-activesupportloggerthreadsafelevellogger-nameerror
  gem "concurrent-ruby", '<=1.3.5'
end

# Specify your gem's dependencies in solargraph_rails.gemspec
gemspec


solargraph_version = (ENV['CI'] && ENV['MATRIX_SOLARGRAPH_VERSION']) || "0.55.alpha"

if solargraph_version == '0.55.alpha'
  gem 'solargraph',
      github: 'apiology/solargraph',
      branch: '2025-04-28'
    # path: '../solargraph'
end

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
