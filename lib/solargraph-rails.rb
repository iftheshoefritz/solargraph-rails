# frozen_string_literal: true

require 'solargraph'
require 'solargraph/rails/version'
require_relative 'solargraph/rails/pin_creator'
require_relative 'solargraph/rails/ruby_parser'
require_relative 'solargraph/rails/files_loader'

module Solargraph
  module Rails
    class DynamicAttributes < Solargraph::Convention::Base
      def global yard_map
        Solargraph::Environ.new(pins: parse_models)
      end

      private

      def parse_models
        pins = []

        FilesLoader.new(
          Dir[File.join(Dir.pwd, 'app', 'models', '**', '*.rb')]
        ).each { |file, contents| pins.push *PinCreator.new(file, contents).create_pins }

        pins
      end
    end
  end
end


Solargraph::Convention.register Solargraph::Rails::DynamicAttributes
