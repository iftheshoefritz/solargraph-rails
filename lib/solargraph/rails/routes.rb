module Solargraph
  module Rails
    # Types the routes DSL and links its literals to controllers, so going to
    # the definition of `:posts` in `resources :posts` jumps to PostsController
    # and of `"posts#index"` in `root "posts#index"` to its index action.
    class Routes
      ROUTE_SET = 'ActionDispatch::Routing::RouteSet'.freeze
      MAPPER = 'ActionDispatch::Routing::Mapper'.freeze
      RESOURCES = "#{MAPPER}::Resources".freeze
      SCOPING = "#{MAPPER}::Scoping".freeze
      HTTP_HELPERS = "#{MAPPER}::HttpHelpers".freeze

      # The parameters of a verb route that take a `"controller#action"` String: Rails names them
      # to and mapping, its RBS to and path_to_endpoint_and_options
      VERB_PARAMETERS = %w[to mapping path_to_endpoint_and_options].freeze

      # The routing methods and parameters that take a `"controller#action"` String, as
      # [method namespace, method name, parameter name]. Rails names root's parameter path, its
      # RBS to.
      ACTION_PARAMETERS = (
        [[RESOURCES, 'root', 'to'], [RESOURCES, 'root', 'path']] +
        [*%w[get post put patch delete options].map { |verb| [HTTP_HELPERS, verb] }, [RESOURCES, 'match']]
          .flat_map do |method_namespace, method_name|
            VERB_PARAMETERS.map { |param_name| [method_namespace, method_name, param_name] }
          end
      ).freeze

      # @return [Routes]
      def self.instance
        @instance ||= new
      end

      # Whether Solargraph can go to definitions from literal arguments.
      #
      # @return [Boolean]
      def self.supported?
        defined?(Solargraph::Pin::FactoryParameter) ? true : false
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

      # @param source_map [Solargraph::SourceMap]
      # @return [Array<Solargraph::Pin::Base>]
      def process(source_map)
        return [] unless self.class.supported?

        controllers = source_map.pins.select do |pin|
          pin.is_a?(Solargraph::Pin::Namespace) && pin.type == :class && routable?(pin.path)
        end
        return [] if controllers.empty?

        actions = source_map.pins.select do |pin|
          pin.is_a?(Solargraph::Pin::Method) && pin.scope == :instance && pin.visibility == :public
        end.group_by(&:namespace)
        controllers.flat_map do |controller|
          controller_pins(controller) + action_pins(controller, actions.fetch(controller.path, []))
        end
      end

      private

      # @param controller [Solargraph::Pin::Namespace]
      # @return [Array<Solargraph::Pin::Base>]
      def controller_pins(controller)
        *namespaces, name = controller_path(controller).split('/')
        location = controller.location
        pins = [
          build(RESOURCES, 'resources', 'resources', name.to_sym, location, decl: :restarg),
          build(RESOURCES, 'resource', 'resources', name.singularize.to_sym, location, decl: :restarg),
          build(SCOPING, 'controller', 'controller', name.to_sym, location)
        ]
        # Resources and Scoping both define namespace
        pins + namespaces.product([RESOURCES, SCOPING]).map do |namespace, method_namespace|
          build(method_namespace, 'namespace', 'name', namespace.to_sym, location)
        end
      end

      # @param path [String]
      # @return [Boolean] false for ApplicationController, which no route points to
      def routable?(path)
        path.end_with?('Controller') && path.split('::').last != 'ApplicationController'
      end

      # @param controller [Solargraph::Pin::Namespace]
      # @param actions [Array<Solargraph::Pin::Method>] its public instance methods
      # @return [Array<Solargraph::Pin::Base>]
      def action_pins(controller, actions)
        actions.product(ACTION_PARAMETERS).map do |action, (method_namespace, method_name, param_name)|
          value = "#{controller_path(controller)}##{action.name}"
          build(method_namespace, method_name, param_name, value, action.location)
        end
      end

      # @param controller [Solargraph::Pin::Namespace]
      # @return [String] e.g. `admin/posts` for `Admin::PostsController`
      def controller_path(controller)
        controller.path.underscore.delete_suffix('_controller')
      end

      # @param method_namespace [String]
      # @param method_name [String]
      # @param param_name [String]
      # @param value [String, Symbol]
      # @param location [Solargraph::Location, nil]
      # @param decl [Symbol]
      # @return [Solargraph::Pin::Base] a FactoryParameter, which older Solargraph versions lack
      def build(method_namespace, method_name, param_name, value, location, decl: :arg)
        Solargraph::Pin::FactoryParameter.new(
          method_name: method_name,
          method_namespace: method_namespace,
          method_scope: :instance,
          param_name: param_name,
          value: value,
          decl: decl,
          return_type: nil,
          location: location
        )
      end
    end
  end
end
