# frozen_string_literal: true

module Solargraph
  module Rails
    class Puma
      EMPTY_ENVIRON = Environ.new

      def self.instance
        @instance ||= new
      end

      # @param environ [Solargraph::Environ]
      # @param source_map [Solargraph::SourceMap]
      #
      # @return [void]
      # @param [Object] basename
      def add_dsl(environ, basename)
        return unless basename == 'puma.rb'

        environ.requires.push('puma')
        environ.domains.push('Puma::DSL')

        Solargraph.logger.warn(
          "[Rails][Puma] added DSL to environ: #{environ.inspect}"
        )
      end
    end
  end
end
