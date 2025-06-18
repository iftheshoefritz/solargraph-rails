source 'https://rubygems.org'

# Kind of ugly, but works. The setup-ruby action forces gems to be installed to vendor/bundle
# If we use it naively we end up with vendor/bundle  and spec/rails*/vendor/bundle, which
# breaks all the tests because docs are generated in two different directories.
#
# So if we just install the rails deps at the same time, we have a single cache and a single
# directory for gems.
rails_version = (ENV['CI'] && ENV['MATRIX_RAILS_VERSION']) || '7.2'
rails_major_version = rails_version.split('.').first
instance_eval File.read(File.expand_path("spec/rails#{rails_major_version}/Gemfile", __dir__))

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

group :development, :rubocop do
  gem 'rubocop', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-performance', require: false
end

if rails_major_version == '7'
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
elsif solargraph_force_ci_version == '0.55.alpha'
  gem 'solargraph',
      github: 'apiology/solargraph',
      branch: '2025-04-28'
      # path: '../solargraph'
else
  gem 'solargraph'
end

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
