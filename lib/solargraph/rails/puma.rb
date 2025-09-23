# frozen_string_literal: true

module Solargraph
  module Rails
    class Puma
      def self.instance
        @instance ||= self.new
      end

      # @param source_map [Solargraph::SourceMap]
      def local(source_map)
        basename = File.basename(source_map.filename)
        return EMPTY_ENVIRON unless basename == 'puma.rb'

        @local ||= Environ.new(
          requires: ['puma'],
          domains: ['::Puma::DSL']
        )
      end
    end
  end
end
