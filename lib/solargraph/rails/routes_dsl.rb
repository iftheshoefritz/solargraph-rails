module Solargraph
  module Rails
    module RoutesDsl
      def self.local(source_map)
        return unless source_map.filename.end_with?('routes.rb')

        block = source_map.pins.find do |pin|
          pin.is_a?(Pin::Block) && pin.receiver&.source&.end_with?('.draw')
        end

        block.instance_variable_set(:@binder, ComplexType.parse('ActionDispatch::Routing::Mapper')) if block
      end
    end
  end
end
