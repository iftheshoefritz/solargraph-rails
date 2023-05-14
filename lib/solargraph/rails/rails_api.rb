module Solargraph
  module Rails
    class RailsApi
      def self.instance
        @instance ||= self.new
      end

      def extra_source_maps
        @extra_source_maps ||= Dir[File.join(__dir__, 'annotations', '*.rb')].to_h do |path|
          code = File.read(path)
          source = Solargraph::Source.load_string(code, path)
          map = Solargraph::SourceMap.map(source)
          [File.basename(path, '.rb'), map]
        end
      end

      # @param yard_map [YardMap]
      def global(_yard_map)
        extra_source_maps.values.flat_map(&:pins)
      end

      def local(source_map, ns)
        return [] unless source_map.filename.include?('db/migrate')
        node, _ = Walker.normalize_ast(source_map.source)

        pins = [
          Util.build_module_include(
            ns,
            'ActiveRecord::ConnectionAdapters::SchemaStatements',
            Util.build_location(node, ns.filename)
          ),
          Util.build_module_extend(
            ns,
            'ActiveRecord::ConnectionAdapters::SchemaStatements',
            Util.build_location(node, ns.filename)
          )
        ]

        Solargraph.logger.debug(
          "[Rails][RailsApi] added #{pins.map(&:name)} to #{ns.path}"
        )
        pins
      end
    end
  end
end
