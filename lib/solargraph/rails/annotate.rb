module Solargraph
  module Rails
    class Annotate
      def self.instance
        @instance ||= self.new
      end

      def self.reset
        @instance = nil
      end

      def initialize
        @schema_present = File.exist?('db/schema.rb')
      end

      def process(source_map, ns)
        return [] if @schema_present
        return [] unless Model.valid_filename?(source_map.filename)

        pins = []
        walker = Walker.from_source(source_map.source)
        walker.comments.each do |_, snip|
          name, type = snip.text.gsub(/[\(\),:\d]/, '').split[1..2]

          next unless name && type

          ruby_type = Schema::RUBY_TYPES[type.to_sym]
          next unless ruby_type

          pins <<
            Util.build_public_method(
              ns,
              name,
              types: [ruby_type],
              location:
                Solargraph::Location.new(source_map.filename, snip.range)
            )
        end

        pins
      end
    end
  end
end
