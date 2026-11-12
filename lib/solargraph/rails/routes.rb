module Solargraph
  module Rails
    # Types the routes DSL.
    class Routes
      ROUTE_SET = 'ActionDispatch::Routing::RouteSet'.freeze
      MAPPER = 'ActionDispatch::Routing::Mapper'.freeze

      # @return [Routes]
      def self.instance
        @instance ||= new
      end

      # RBS types the draw block with `[self: Mapper]`, which Solargraph does
      # not read.
      #
      # @param api_map [Solargraph::ApiMap]
      # @param rooted_tag [String]
      # @param scope [Symbol]
      # @return [Array<Solargraph::Pin::Method>]
      def object(api_map, rooted_tag, scope)
        return [] unless scope == :instance && rooted_tag.delete_prefix('::') == ROUTE_SET

        location = api_map.get_path_pins("#{ROUTE_SET}#draw").find(&:location)&.location
        [
          Util.build_public_method(
            Solargraph::Pin::Namespace.new(name: ROUTE_SET),
            'draw',
            comments: "@yieldself [#{MAPPER}]\n@yieldreceiver [#{MAPPER}]",
            types: ['void'],
            location: location
          )
        ]
      end
    end
  end
end
