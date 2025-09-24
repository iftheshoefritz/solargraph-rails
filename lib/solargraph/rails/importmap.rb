# frozen_string_literal: true

module Solargraph
  module Rails
    class Importmap
      EMPTY_ENVIRON = Environ.new

      # @return [Solargraph::Rails::Puma]
      def self.instance
        @instance ||= new
      end

      # @param environ [Solargraph::Environ]
      # @param basename [String]
      #
      # @return [void]
      def add_dsl(environ, basename)
        return unless basename == 'importmap.rb'

        environ.requires.push('importmap-rails')
        environ.domains.push('Importmap::Map')

        Solargraph.logger.debug(
          "[Rails][Importmap] added DSL to environ: #{environ.inspect}"
        )
      end
    end
  end
end
