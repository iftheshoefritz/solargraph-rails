module Solargraph
  module Rails
    class Model
      def self.instance
        @instance ||= self.new
      end

      def self.valid_filename?(filename)
        filename.include?('app/models')
      end

      # @param source_map [Solargraph::SourceMap]
      # @param ns [Solargraph::Pin::Namespace]
      def process(source_map, ns)
        return [] unless self.class.valid_filename?(source_map.filename)

        pins = []
        abstract = false

        # ActiveRecord defines a hidden subclass of ActiveRecord::Relation for
        # each model class that inherits from ActiveRecord::Base.
        pins << relation = Solargraph::Pin::Namespace.new(
          name: 'ActiveRecord_Relation',
          type: :class,
          visibility: :private,
          closure: ns,
        )
        pins << Solargraph::Pin::Reference::Superclass.new(
          name: "ActiveRecord::Relation",
          closure: relation,
        )

        pins << Solargraph::Pin::Method.new(
          name: 'model',
          scope: :instance,
          closure: relation,
          comments: "@return [Class<#{ns.name}>]"
        )

        walker = Walker.from_source(source_map.source)

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

        walker.on :send, [:self, :abstract_class=, :true] do |ast|
          abstract = true
        end

        walker.on :send, [nil, :scope] do |ast|
          next if ast.children[2].nil?
          name = ast.children[2].children.last

          parameters = []

          if ast.children.last.type == :block
            location = ast.children.last.location
            block_pin = source_map.locate_block_pin(location.line, location.column)
            parameters.concat(block_pin.parameters.clone)
          end

          location = Util.build_location(ast, ns.filename)
          # define scopes as a class methods on the model, and instance methods
          # on the hidden relation class
          pins << Util.build_public_method(
            ns,
            name.to_s,
            scope: :class,
            parameters: parameters,
            types: [relation_type(ns.name)],
            location: location
          )
          pins << Util.build_public_method(
            relation,
            name.to_s,
            scope: :instance,
            parameters: parameters,
            types: [relation_type(ns.name)],
            location: location
          )
        end

        walker.walk

        # Class methods on the model are exposed as *instance* methods on the
        # hidden ActiveRecord_Relation class.
        #
        # Uses DelegatedMethod pins (instead of build_public_method) so Solargraph
        # will show the "real" method pin for type inference, probing, docs etc.
        source_map.pins.each do |pin|
          next unless pin.is_a?(Solargraph::Pin::Method) && pin.scope == :class && pin.closure == ns

          pins << Solargraph::Pin::DelegatedMethod.new(closure: relation, scope: :instance, method: pin)
        end


        unless abstract
          pins += relation_method_pins(ns, :class, ns.path)
          pins += relation_method_pins(relation, :instance, ns.path)
        end

        Solargraph.logger.debug("[Rails][Model] added #{pins.map(&:name)} to #{ns.path}")

        pins
      end


      def plural_association(ns, ast)
        association_name = ast.children[2].children.first
        class_name =
          extract_custom_class_name(ast) ||
            association_name.to_s.singularize.camelize

        Util.build_public_method(
          ns,
          association_name.to_s,
          types: [relation_type(class_name)],
          location: Util.build_location(ast, ns.filename)
        )
      end

      def singular_association(ns, ast)
        association_name = ast.children[2].children.first
        class_name =
          extract_custom_class_name(ast) || association_name.to_s.camelize

        Util.build_public_method(
          ns,
          association_name.to_s,
          types: [class_name],
          location: Util.build_location(ast, ns.filename)
        )
      end

      def extract_custom_class_name(ast)
        node = Util.extract_option(ast, :class_name)
        return unless node && node.type == :str

        node.children.last
      end

      # Generate method pins for ActiveRecord methods in the given namespace/scope, where the
      # the return types will be templated with the provided model class.
      #
      # These method pins don't need to include any documentation, as Solargraph will merge
      # documentation from Rails when it resolves the "method stack" for each pin.
      #
      # @param ns [Solargraph::Pin::Namespace] the namespace (model or relation class) in which to define methods.
      # @param scope [:instance, :class] the method scope (:class for the model and :instance for the relation).
      # @param model_class [String] the model class (e.g. "Person") that should be used in return types.
      # @return [Array<Solargraph::Pin::Method>]
      def relation_method_pins(namespace, scope, model_class)
        pins = []
        RETURNS_RELATION.each do |method|
          pins << Util.build_public_method(namespace, method, scope: scope, types: [relation_type(model_class)])
        end
        RETURNS_INSTANCE.each do |method|
          pins << Util.build_public_method(namespace, method, scope: scope, types: [model_class])
        end
        OVERLOADED.each do |method, overloads|
          comments = overloads.map do |args, lines|
            lines = ["@return [#{lines}]"] if lines.is_a?(String)
            lines = ["@overload #{method}#{args}"] + lines
            lines.map { |line| line.gsub '$T', model_class }.join("\n  ")
          end
          pins << Util.build_public_method(namespace, method, scope: scope, comments: comments.join("\n"))
        end
        pins
      end

      # construct the type name for the models hidden relation class.
      # the additional type parameter is _not_ redundant, it makes enumerable methods work.
      def relation_type(model_path)
        "#{model_path}::ActiveRecord_Relation"
      end
      
      RETURNS_RELATION = %w[
        all
        and
        annotate
        distinct
        eager_load
        excluding
        from
        group
        having
        in_order_of
        includes
        invert_where
        joins
        left_joins
        left_outer_joins
        limit
        lock
        none
        offset
        or
        order
        preload
        readonly
        references
        reorder
        reselect
        reverse_order
        rewhere
        select
        strict_loading
        unscope
        where
        without
      ]

      RETURNS_INSTANCE = %w[
        find
        find_by find_by!
        take
        take!
        sole find_sole_by
        first  second  third  fourth  fifth  third_to_last  second_to_last  last
        first! second! third! fourth! fifth! third_to_last! second_to_last! last!
        forty_two
        forty_two!
      ]

      OVERLOADED = {
        "where" => {
          "()" => "ActiveRecord::QueryMethods::WhereChain<$T::ActiveRecord_Relation>",
          "(*args)" => "$T::ActiveRecord_Relation",
        },
        "select" => {
          "()" => [
            "@yieldparam [$T]",
            "@return [Array<$T>]",
          ],
          "(*args)" => "$T::ActiveRecord_Relation",
        },
        "find" => {
          "(id)" => [
            "@param id [Integer, String]",
            "@return [$T]"
          ],
          "(*ids)" => "Array<$T>",
        },
        "take" => {
          "()" => "T, nil",
          "(limit)" => "Array<$T>",
        },
        "first" => {
          "()" => "$T, nil",
          "(limit)" => "Array<$T>",
        },
        "last" => {
          "()" => "$T, nil",
          "(limit)" => "Array<$T>"
        },
      }
    end
  end
end
