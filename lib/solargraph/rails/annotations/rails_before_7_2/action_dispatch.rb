module ActionDispatch
  module Routing
    class Mapper
      # Rails 7.0 and 7.1 resolve actionpack 6.0 RBS, which does not type
      # the routing DSL; gem_rbs_collection types it from actionpack 7.2:
      # https://github.com/ruby/gem_rbs_collection/pull/1106

      module Base
        # @return [self]
        def mount(app, options = nil); end

        # @return [self]
        def with_default_scope(scope); end
      end

      module HttpHelpers
        # @return [self]
        def get(*args); end

        # @return [self]
        def post(*args); end

        # @return [self]
        def patch(*args); end

        # @return [self]
        def put(*args); end

        # @return [self]
        def delete(*args); end

        # @return [self]
        def options(*args); end
      end

      module Scoping
        # @return [self]
        def scope(*args); end

        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def controller(controller); end

        # @return [self]
        def constraints(constraints = {}); end

        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def defaults(defaults = {}); end
      end

      module Concerns
        # rubocop:disable YARD/TagTypeSyntax -- _Concern is an RBS interface

        # @return [ActionDispatch::Routing::Mapper::_Concern, Proc]
        def concern(name, callable = nil); end
        # rubocop:enable YARD/TagTypeSyntax

        # @return [Array<Symbol>]
        def concerns(*args); end
      end

      module Resources
        # @return [self]
        def resource(*resources); end

        # @return [self]
        def resources(*resources); end

        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def collection; end

        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def member; end

        # @return [self]
        def nested; end

        # @return [self]
        def namespace(path, options = {}); end

        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def shallow; end

        # @return [self]
        def match(path, *rest); end

        # @return [self]
        def root(path, options = {}); end
      end
    end
  end
end
