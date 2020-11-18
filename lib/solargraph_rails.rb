# frozen_string_literal: true

require 'solargraph_rails/version'
require 'solargraph'
require_relative 'solargraph_rails/parser'
require_relative 'solargraph_rails/ruby_parser'
require_relative 'solargraph_rails/files_loader'

module SolargraphRails
  class DynamicAttributes < Solargraph::Convention::Base
    def global yard_map
      Solargraph::Environ.new(pins: parse_models)
    end

    private

    def parse_models
      pins = []

      FilesLoader.new(
        Dir[File.join(Dir.pwd, 'app', 'models', '**', '*.rb')]
      ).each { |file, contents| pins.push *Parser.new(file, contents).parse }

      pins
    end
  end
end


Solargraph::Convention.register SolargraphRails::DynamicAttributes
