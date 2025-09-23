# frozen_string_literal: true

module Solargraph
  module Convention
    class Rakefile < Base
      # @param source_map [Solargraph::SourceMap]
      def local(source_map)
        basename = File.basename(source_map.filename)
        return EMPTY_ENVIRON unless basename == 'puma.rb'

        @local ||= Environ.new(
          requires: ['puma'],
          domains: ['Puma::DSL']
        )
      end
    end
  end
end
