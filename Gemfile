source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

group :development, :test do
  gem 'byebug'
  gem 'bundler-audit'
end
# Specify your gem's dependencies in solargraph_rails.gemspec
gemspec

# Local gemfile for development tools, etc.
local_gemfile = File.expand_path(".Gemfile", __dir__)
instance_eval File.read local_gemfile if File.exist? local_gemfile
