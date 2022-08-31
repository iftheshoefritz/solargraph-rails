module Solargraph
  module Rails
    class Model
      def self.instance
        @instance ||= self.new
      end

      def self.valid_filename?(filename)
        filename.include?('app/models')
      end

      def process(source_map, ns)
        return [] unless self.class.valid_filename?(source_map.filename)

        walker = Walker.from_source(source_map.source)
        pins = []

        walker.on :send, [nil, :belongs_to] do |ast|
          pins << singular_association(ns, ast)
        end

        walker.on :send, [nil, :has_one] do |ast|
          pins << singular_association(ns, ast)
        end

        walker.on :send, [nil, :has_many] do |ast|
          pins << plural_association(ns, ast)
        end

        walker.on :send, [nil, :has_and_belongs_to_many] do |ast|
          pins << plural_association(ns, ast)
        end

        walker.on :send, [nil, :scope] do |ast|
          next if ast.children[2].nil?
          name = ast.children[2].children.last

          method_pin =
            Util.build_public_method(
              ns,
              name.to_s,
              types: ns.return_type.map(&:tag),
              scope: :class,
              location: Util.build_location(ast, ns.filename)
            )

          if ast.children.last.type == :block
            location = ast.children.last.location
            block_pin =
              source_map.locate_block_pin(location.line, location.column)
            method_pin.parameters.concat(block_pin.parameters.clone)
          end
          pins << method_pin
        end

        walker.walk
        if pins.any?
          Solargraph.logger.debug(
            "[Rails][Model] added #{pins.map(&:name)} to #{ns.path}"
          )
        end
        pins
      end

      def plural_association(ns, ast)
        relation_name = ast.children[2].children.first
        class_name =
          extract_custom_class_name(ast) ||
            relation_name.to_s.singularize.camelize

        Util.build_public_method(
          ns,
          relation_name.to_s,
          types: ["ActiveRecord::Associations::CollectionProxy<#{class_name}>"],
          location: Util.build_location(ast, ns.filename)
        )
      end

      def singular_association(ns, ast)
        relation_name = ast.children[2].children.first
        class_name =
          extract_custom_class_name(ast) || relation_name.to_s.camelize

        Util.build_public_method(
          ns,
          relation_name.to_s,
          types: [class_name],
          location: Util.build_location(ast, ns.filename)
        )
      end

      def extract_custom_class_name(ast)
        options = ast.children[3..-1].find { |n| n.type == :hash }
        return unless options

        class_name_pair =
          options.children.find do |n|
            n.children[0].deconstruct == %i[sym class_name] &&
              n.children[1].type == :str
          end
        class_name_pair && class_name_pair.children.last.children.last
      end
    end
  end
end
