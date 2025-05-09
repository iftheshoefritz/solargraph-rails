# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = 'auto_yard'
  spec.version = '0.0.1'
  spec.authors = ['Stephen Sugden']
  spec.email = ['grncdr@users.noreply.github.com']

  spec.summary = 'Run yard gems automatically after bundle install'
  spec.description = spec.summary
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.6.0'

  spec.homepage = 'https://github.com'
  spec.metadata['homepage_uri'] = spec.homepage

  spec.files = ['plugins.rb']
end
