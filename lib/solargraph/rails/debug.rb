module Solargraph
  module Rails
    class Debug
      def self.run(query = nil)
        self.new.run(query)
      end

      def run(query)
        Solargraph.logger.level = Logger::DEBUG

        api_map = Solargraph::ApiMap.load('./')

        puts "Ruby version: #{RUBY_VERSION}"
        puts "Solargraph version: #{Solargraph::VERSION}"
        puts "Solargraph Rails version: #{Solargraph::Rails::VERSION}"

        return unless query

        puts "Known methods for #{query}"

        pin = api_map.pins.find { |p| p.path == query }
        return unless pin

        api_map
          .get_complex_type_methods(pin.return_type)
          .each { |pin| puts "- #{pin.path}" }
      end
    end
  end
end
