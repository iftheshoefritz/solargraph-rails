require 'solargraph'
require 'logger'
require 'active_support'
require 'active_support/core_ext/string/inflections'

require_relative 'solargraph/rails/util'
require_relative 'solargraph/rails/schema'
require_relative 'solargraph/rails/annotate'
require_relative 'solargraph/rails/autoload'
require_relative 'solargraph/rails/model'
require_relative 'solargraph/rails/devise'
require_relative 'solargraph/rails/walker'
require_relative 'solargraph/rails/rails_api'
require_relative 'solargraph/rails/routes_dsl'
require_relative 'solargraph/rails/delegate'
require_relative 'solargraph/rails/storage'
require_relative 'solargraph/rails/debug'
require_relative 'solargraph/rails/version'

module Solargraph
  module Rails
    class NodeParser
      extend Solargraph::Parser::Legacy::ClassMethods
    end

    class Convention < Solargraph::Convention::Base
      def global(yard_map)
        Solargraph::Environ.new(
          pins: Solargraph::Rails::RailsApi.instance.global(yard_map)
        )
      rescue => error
        Solargraph.logger.warn(
          error.message + "\n" + error.backtrace.join("\n")
        )
        EMPTY_ENVIRON
      end

      def local(source_map)
        run_feature { RoutesDsl.local(source_map) }

        pins = []
        ds = source_map.document_symbols.select do |n|
          n.is_a?(Solargraph::Pin::Namespace)
        end
        ns = ds.find { |s| s.type == :class }

        return EMPTY_ENVIRON unless ns

        pins += run_feature { Schema.instance.process(source_map, ns) }
        pins += run_feature { Annotate.instance.process(source_map, ns) }
        pins += run_feature { Model.instance.process(source_map, ns) }
        pins += run_feature { Storage.instance.process(source_map, ns) }
        pins += run_feature { Autoload.instance.process(source_map, ns, ds) }
        pins += run_feature { Devise.instance.process(source_map, ns) }
        pins += run_feature { Delegate.instance.process(source_map, ns) } if Delegate.supported?
        pins += run_feature { RailsApi.instance.local(source_map, ns) }

        Solargraph::Environ.new(pins: pins)
      end

      private

      def run_feature(&block)
        yield
      rescue => error
        Solargraph.logger.warn(
          error.message + "\n" + error.backtrace.join("\n")
        )
        []
      end
    end
  end
end

Solargraph::Convention.register(Solargraph::Rails::Convention)
