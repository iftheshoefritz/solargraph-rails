module Solargraph
  module Rails
    # gem_rbs_collection types ActiveRecord's query methods in generic modules
    # that only rbs_rails-generated model signatures mix in, e.g.
    #
    #   extend ActiveRecord::Base::ClassMethods[User, User::ActiveRecord_Relation, Integer]
    #
    # This supplies those mixins with their type arguments bound.
    class QueryGenerics
      CLASS_METHODS = 'ActiveRecord::Base::ClassMethods'.freeze
      RELATION_METHODS = 'ActiveRecord::Relation::Methods'.freeze
      PRIMARY_KEY = 'Integer'.freeze

      # Unbound or misbound mixin generics leak `generic<Model>` into every
      # query method, so this needs both:
      # https://github.com/castwide/solargraph/pull/1344 (generics on extends) and
      # https://github.com/castwide/solargraph/pull/1415 (binding by position)
      def self.supported?
        return @supported if defined?(@supported)

        @supported = Solargraph::Pin::Reference.method_defined?(:generic_values) &&
                     Solargraph::Parser::ParserGem::NodeMethods.respond_to?(:trailing_rbs_type_args) &&
                     binds_by_position?
      end

      # @return [Boolean]
      def self.binds_by_position?
        pair = Solargraph::Pin::Namespace.new(name: 'Pair', generics: %w[A B])
        second = Solargraph::ComplexType.parse('generic<B>')
        second.resolve_generics(pair, Solargraph::ComplexType.parse('Pair<String, Integer>')).tag == 'Integer'
      end
      private_class_method :binds_by_position?

      # `self` binds Model to whichever class receives the call.
      #
      # @param pins [Array<Solargraph::Pin::Base>] pins declaring ActiveRecord::Base
      # @return [Array<Solargraph::Pin::Reference>]
      def self.base_pins(pins)
        base = pins.find { |pin| pin.is_a?(Solargraph::Pin::Namespace) && pin.path == 'ActiveRecord::Base' }
        return [] unless base && supported?

        [mixin(Solargraph::Pin::Reference::Extend, base, CLASS_METHODS,
               ['self', 'ActiveRecord::Relation', PRIMARY_KEY])]
      end

      # @param model [Solargraph::Pin::Namespace]
      # @param relation [Solargraph::Pin::Namespace] the model's ActiveRecord_Relation
      # @return [Array<Solargraph::Pin::Reference>]
      def self.model_pins(model, relation)
        return [] unless supported?

        [
          mixin(Solargraph::Pin::Reference::Extend, model, CLASS_METHODS,
                [model.path, relation.path, PRIMARY_KEY]),
          mixin(Solargraph::Pin::Reference::Include, relation, RELATION_METHODS,
                [model.path, PRIMARY_KEY])
        ]
      end

      # @param klass [Class<Solargraph::Pin::Reference>]
      # @param closure [Solargraph::Pin::Namespace]
      # @param name [String]
      # @param generic_values [Array<String>]
      # @return [Solargraph::Pin::Reference]
      def self.mixin(klass, closure, name, generic_values)
        klass.new(closure: closure, name: name, generic_values: generic_values)
      end
      private_class_method :mixin
    end
  end
end
