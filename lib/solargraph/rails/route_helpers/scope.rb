module Solargraph
  module Rails
    class RouteHelpers
      # A static copy of ActionDispatch::Routing::Mapper::Scope (actionpack's action_dispatch/routing/mapper.rb): a
      # chain of frames, each merging its options over its parent's, with the level of the DSL method that opened it.
      class Scope
        include Enumerable

        RESOURCE_SCOPES = %i[resource resources].freeze
        RESOURCE_METHOD_SCOPES = %i[collection member new].freeze

        # @return [Scope, nil]
        attr_reader :parent

        # @return [Symbol, nil] e.g. :resources, :member, :nested
        attr_reader :scope_level

        # @return [Hash{Symbol => Object}]
        attr_reader :frame

        # @param hash [Hash{Symbol => Object}]
        # @param parent [Scope, nil]
        # @param scope_level [Symbol, nil]
        def initialize(hash, parent = nil, scope_level = nil)
          @parent = parent
          @frame = parent ? parent.frame.merge(hash) : hash
          @scope_level = scope_level
        end

        # @param hash [Hash{Symbol => Object}]
        # @return [Scope]
        def new(hash)
          self.class.new(hash, self, scope_level)
        end

        # @param level [Symbol]
        # @return [Scope]
        def new_level(level)
          self.class.new(frame, self, level)
        end

        # @param key [Symbol]
        # @return [Object, nil]
        def [](key)
          frame[key]
        end

        # @return [Boolean]
        def root?
          parent.nil?
        end

        # @return [Boolean]
        def nested?
          scope_level == :nested
        end

        # @return [Boolean]
        def resources?
          scope_level == :resources
        end

        # @return [Boolean]
        def resource_scope?
          RESOURCE_SCOPES.include?(scope_level)
        end

        # @return [Boolean]
        def resource_method_scope?
          RESOURCE_METHOD_SCOPES.include?(scope_level)
        end

        # The parts of a route name, in order, by the scope it is defined in (Scope#action_name).
        #
        # @param name_prefix [String, nil] the scope's `as`
        # @param prefix [String, nil] the route's own name, or its action's
        # @param collection_name [String, nil]
        # @param member_name [String, nil]
        # @return [Array<String, Symbol, nil>]
        def action_name(name_prefix, prefix, collection_name, member_name)
          case scope_level
          when :nested then [name_prefix, prefix]
          when :collection then [prefix, name_prefix, collection_name]
          when :new then [prefix, :new, name_prefix, member_name]
          when :member then [prefix, name_prefix, member_name]
          when :root then [name_prefix, collection_name, prefix]
          else [name_prefix, member_name, prefix]
          end
        end

        # @yieldparam scope [Scope]
        # @return [void]
        def each
          node = self
          until node.nil?
            yield node
            node = node.parent
          end
        end
      end
    end
  end
end
