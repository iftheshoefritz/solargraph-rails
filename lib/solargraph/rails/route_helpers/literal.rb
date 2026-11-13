module Solargraph
  module Rails
    class RouteHelpers
      # The values of literal arguments in a routes file, e.g. `:posts` or `{ only: [:index] }`.
      module Literal
        # The value of an argument that isn't a literal
        UNKNOWN = Object.new.freeze

        # A constant argument, e.g. the app of `mount Blog::Engine`
        #
        # @param name [String]
        Const = Struct.new(:name)

        module_function

        # @param node [::Parser::AST::Node, nil]
        # @return [Object] the node's value, or UNKNOWN
        def value(node)
          return nil if node.nil?

          case node.type
          when :sym, :str, :int then node.children[0]
          when :dsym then plain_string(node)&.to_sym || UNKNOWN
          when :dstr then plain_string(node) || UNKNOWN
          when :true then true # rubocop:disable Lint/BooleanSymbol
          when :false then false # rubocop:disable Lint/BooleanSymbol
          when :nil then nil
          when :array then node.children.map { |child| value(child) }
          when :hash, :kwargs then hash_value(node)
          when :const then const_value(node)
          when :regexp then //
          else UNKNOWN
          end
        end

        # @param node [::Parser::AST::Node] a :dstr or :dsym node
        # @return [String, nil] its text, unless it interpolates
        def plain_string(node)
          node.children.map { |child| child.type == :str ? child.children[0] : (return nil) }.join
        end

        # @param node [::Parser::AST::Node]
        # @return [Hash, Object]
        def hash_value(node)
          node.children.each_with_object({}) do |pair, hash|
            return UNKNOWN unless pair.type == :pair

            key = value(pair.children[0])
            return UNKNOWN unless key.is_a?(Symbol) || key.is_a?(String) || key.is_a?(Const)

            hash[key] = value(pair.children[1])
          end
        end

        # @param node [::Parser::AST::Node]
        # @return [Const, Object]
        def const_value(node)
          scope, name = node.children
          return Const.new(name.to_s) if scope.nil? || scope.type == :cbase

          parent = const_value(scope)
          parent.is_a?(Const) ? Const.new("#{parent.name}::#{name}") : UNKNOWN
        end
      end
    end
  end
end
