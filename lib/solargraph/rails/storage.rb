module Solargraph
  module Rails
    class Storage
      def self.instance
        @instance ||= self.new
      end

      def process(source_map, ns)
        return [] unless Model.valid_filename?(source_map.filename)

        walker = Walker.from_source(source_map.source)
        pins = []

        walker.on :send, [nil, :has_one_attached] do |ast|
          name = ast.children[2].children.first

          pins <<
            Util.build_public_method(
              ns,
              name.to_s,
              types: ['ActiveStorage::Attached::One'],
              location: Util.build_location(ast, ns.filename)
            )
        end

        walker.on :send, [nil, :has_many_attached] do |ast|
          name = ast.children[2].children.first

          pins <<
            Util.build_public_method(
              ns,
              name.to_s,
              types: ['ActiveStorage::Attached::Many'],
              location: Util.build_location(ast, ns.filename)
            )
        end

        walker.walk
        if pins.any?
          Solargraph.logger.debug(
            "[Rails][Storage] added #{pins.map(&:name)} to #{ns.path}"
          )
        end
        pins
      end
    end
  end
end
