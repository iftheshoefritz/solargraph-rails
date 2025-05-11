source 'https://rubygems.org'


# Kind of ugly, but works. The setup-ruby action forces gems to be installed to vendor/bundle
# If we use it naively we end up with vendor/bundle  and spec/rails7/vendor/bundle, which
# breaks all the tests because docs are generated in two different directories.
#
# So if we just install the rails deps at the same time, we have a single cache and a single
# directory for gems.
rails_version = ENV['MATRIX_RAILS_VERSION'] || '7'
relative_filename = "spec/rails#{rails_version}/Gemfile"
rails_gemfile = File.expand_path(relative_filename, __dir__)
instance_eval File.read(rails_gemfile)

group :development, :test do
  gem 'bundler-audit'
  gem 'debug'
  gem 'byebug'
end

# Specify your gem's dependencies in solargraph_rails.gemspec
gemspec
