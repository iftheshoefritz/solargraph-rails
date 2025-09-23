# frozen_string_literal: true

module Solargraph
  module Convention
    class Rakefile < Base
      def local source_map
        basename = File.basename(source_map.filename)
        return EMPTY_ENVIRON unless basename == 'puma.rb'

        @environ ||= Environ.new(
          requires: ['puma'],
          domains: ['Puma::DSL']
        )
      end
    end
  end
end
