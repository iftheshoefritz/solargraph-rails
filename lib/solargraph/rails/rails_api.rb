module Solargraph
  module Rails
    class RailsApi
      def self.instance
        @instance ||= self.new
      end

      def global(yard_map)
        return [] if yard_map.required.empty?

        ann = File.read(File.dirname(__FILE__) + '/annotations.rb')
        source = Solargraph::Source.load_string(ann, 'annotations.rb')
        map = Solargraph::SourceMap.map(source)

        Solargraph.logger.debug(
          "[Rails][Rails] found #{map.pins.size} pins in annotations"
        )

        overrides =
          YAML
            .load_file(File.dirname(__FILE__) + '/types.yml')
            .map do |meth, data|
              if data['return']
                Util.method_return(meth, data['return'])
              elsif data['yieldself']
                Solargraph::Pin::Reference::Override.from_comment(
                  meth,
                  "@yieldself [#{data['yieldself'].join(',')}]"
                )
              elsif data['yieldparam']
                Solargraph::Pin::Reference::Override.from_comment(
                  meth,
                  "@yieldparam [#{data['yieldparam'].join(',')}]"
                )
              end
            end

        ns =
          Solargraph::Pin::Namespace.new(
            name: 'ActionController::Base',
            gates: ['ActionController::Base']
          )

        definitions = [
          Util.build_public_method(
            ns,
            'response',
            types: ['ActionDispatch::Response'],
            location: Util.dummy_location('whatever.rb')
          ),
          Util.build_public_method(
            ns,
            'request',
            types: ['ActionDispatch::Request'],
            location: Util.dummy_location('whatever.rb')
          ),
          Util.build_public_method(
            ns,
            'session',
            types: ['ActionDispatch::Request::Session'],
            location: Util.dummy_location('whatever.rb')
          ),
          Util.build_public_method(
            ns,
            'flash',
            types: ['ActionDispatch::Flash::FlashHash'],
            location: Util.dummy_location('whatever.rb')
          )
        ]

        map.pins + definitions + overrides
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
