# frozen_string_literal: true

module Solargraph
  module Rails
    class Puma
      EMPTY_ENVIRON = Environ.new

      def self.instance
        @instance ||= self.new
      end

      # @param environ [Solargraph::Environ]
      # @param source_map [Solargraph::SourceMap]
      #
      # @return [void]
      def add_dsl(environ, source_map)
        basename = File.basename(source_map.filename)

        return unless basename == 'puma.rb'

        environ.requires += 'puma'
        environ.domains += '::Puma::DSL'
      end
    end
  end
end
