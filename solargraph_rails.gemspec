
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "solargraph_rails/version"

Gem::Specification.new do |spec|
  spec.name          = "solargraph_rails"
  spec.version       = SolargraphRails::VERSION
  spec.authors       = ["Fritz Meissner"]
  spec.email         = ["fritz.meissner@gmail.com"]

  spec.summary       = %q{Solargraph plugin that adds Rails-specific code through a Convention}
  spec.description   = %q{Add reflection on ActiveModel dynamic attributes that will be created at runtime}
  spec.homepage      = 'https://github.com/iftheshoefritz/solargraph_rails'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "solargraph", "~> 0.40.1"
end
