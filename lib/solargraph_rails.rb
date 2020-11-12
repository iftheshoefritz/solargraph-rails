require 'solargraph_rails/version'
require 'solargraph'
require_relative 'solargraph_rails/parser'

module SolargraphRails
  class DynamicAttributes < Solargraph::Convention::Base
    def global yard_map
      Solargraph::Environ.new(pins: parse_models)
    end

    private

    def parse_models
      loader = FilesLoader.new(
        Dir[File.join(Dir.pwd, 'app', 'models', '**', '*.rb')]
      )

      MultiFileParser.new(loader).parse
    end
  end
end


Solargraph::Convention.register SolargraphRails::DynamicAttributes
