# frozen_string_literal: true

module Solargraph
  module Rails
    class Puma
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
