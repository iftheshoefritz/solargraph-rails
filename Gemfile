source 'https://rubygems.org'

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
source 'https://rubygems.org'

solargraph_version = (ENV['CI'] && ENV['MATRIX_SOLARGRAPH_VERSION'])

# ensure that YARD docs get cached by ruby/setup-ruby in GitHub
# Actions if using an older version of solargraph that needs user to
# run `yard gems` manually
if solargraph_version
  solargraph_minor_version = solargraph_version.split('.')[1].to_i
  solargraph_major_version = solargraph_version.split('.')[0].to_i
  if solargraph_version && solargraph_major_version == 0 && solargraph_minor_version < 53
    plugin 'auto_yard', path: File.expand_path('ci/auto_yard', __dir__)
    STDERR.puts("Using auto_yard plugin at #{File.expand_path('ci/auto_yard', __dir__)}")
  end
end

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
