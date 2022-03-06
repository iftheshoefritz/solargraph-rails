module Solargraph
  module Rails
    class Delegate
      def self.instance
        @instance ||= self.new
      end

      def process(source_map, ns)
        return [] unless source_map.code.include?('delegate')

        walker = Walker.from_source(source_map.source)
        pins = []

        walker.on :send, [nil, :delegate] do |ast|
          methods =
            ast.children[2..-1]
              .map { |c| c.children.first }
              .select { |s| s.is_a?(Symbol) }

          methods.each do |meth|
            pins <<
              Util.build_public_method(
                ns,
                meth.to_s,
                location: Util.build_location(ast, ns.filename)
              )
          end
        end

        walker.walk

        if pins.any?
          Solargraph.logger.debug(
            "[Rails][Delegate] added #{pins.map(&:name)} to #{ns.path}"
          )
        end

        pins
      end
    end
  end
end
