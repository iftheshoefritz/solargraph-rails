require_relative 'route_helpers/scope'
require_relative 'route_helpers/literal'
require_relative 'route_helpers/resource'
require_relative 'route_helpers/mapper'

module Solargraph
  module Rails
    # Types the named route helpers, e.g. post_path and edit_post_url, that Rails generates from the app's routes.
    #
    # Rails defines them on an anonymous module, `Rails.application.routes.url_helpers`, which controllers, views,
    # mailers and integration tests include. Here that module is MODULE, defined by config/routes.rb. Mounted engines'
    # route proxies, which Rails adds to the mounted helpers rather than url_helpers, go on PROXY_MODULE, which the same
    # classes include. Each routes file defines the helpers of the routes it declares, so editing a file refreshes them.
    class RouteHelpers
      MODULE = 'ActionDispatch::Routing::RouteSet::UrlHelpers'.freeze
      PROXY_MODULE = 'ActionDispatch::Routing::RouteSet::MountedEngineHelpers'.freeze
      PROXY_TYPE = 'ActionDispatch::Routing::RoutesProxy'.freeze
      TARGETS = %w[
        ActionController::Base ActionController::API ActionView::Base ActionMailer::Base ActionDispatch::IntegrationTest
      ].freeze

      # @return [RouteHelpers]
      def self.instance
        @instance ||= new
      end

      # @param source_map [Solargraph::SourceMap]
      # @return [Solargraph::Environ]
      def local(source_map)
        filename = source_map.filename.to_s
        return helper_module_environ(source_map) if filename.include?('/app/helpers/')

        root = routes_root(filename)
        return Solargraph::Environ.new unless root

        routes = Mapper.new(root, filename => source_map.source.code).routes
        # The routes one call defines on a path, e.g. the GET, PATCH, PUT and DELETE of `resources` on /posts/:id; other
        # calls on the same path, such as several roots, are different routes
        same_call = routes.select { |route| route.kind == :route }.group_by { |route| call_key(route) }
        pins = routes.select { |route| route.name && route.location.filename == filename }.flat_map do |route|
          helper_pins(route, same_call.fetch(call_key(route), []))
        end
        pins = module_pins(filename) + pins if filename == File.join(root, 'config/routes.rb')
        Solargraph::Environ.new(pins: pins)
      end

      private

      # @param filename [String]
      # @return [String, nil] the app root of config/routes.rb or a file under config/routes/
      def routes_root(filename)
        return filename.delete_suffix('/config/routes.rb') if filename.end_with?('/config/routes.rb')

        filename[%r{\A(.*)/config/routes/.+\.rb\z}, 1]
      end

      # @param filename [String]
      # @param name [String]
      # @return [Solargraph::Pin::Namespace]
      def module_pin(filename, name = MODULE)
        Solargraph::Pin::Namespace.new(
          name: name, type: :module, closure: Solargraph::Pin::ROOT_PIN,
          location: Solargraph::Location.new(filename, Solargraph::Range.from_to(0, 0, 0, 0))
        )
      end

      # The modules, the url helpers extending themselves as Rails' do, their includes into the classes that get url
      # helpers, and the return type of RouteSet#url_helpers.
      #
      # @param filename [String]
      # @return [Array<Solargraph::Pin::Base>]
      def module_pins(filename)
        mod = module_pin(filename)
        includes = TARGETS.product([MODULE, PROXY_MODULE]).map do |target, name|
          Solargraph::Pin::Reference::Include.new(
            name: name, closure: Solargraph::Pin::Namespace.new(name: target, closure: Solargraph::Pin::ROOT_PIN)
          )
        end
        [
          mod,
          module_pin(filename, PROXY_MODULE),
          Solargraph::Pin::Reference::Extend.new(name: MODULE, closure: mod),
          *includes,
          Util.method_return('ActionDispatch::Routing::RouteSet#url_helpers', "Module<#{MODULE}>")
        ]
      end

      # @param source_map [Solargraph::SourceMap]
      # @return [Solargraph::Environ]
      def helper_module_environ(source_map)
        helpers = source_map.pins.select do |pin|
          pin.is_a?(Solargraph::Pin::Namespace) && pin.type == :module && pin.name.end_with?('Helper')
        end
        Solargraph::Environ.new(
          pins: helpers.map { |mod| Solargraph::Pin::Reference::Include.new(name: MODULE, closure: mod) }
        )
      end

      # @param route [Mapper::Route]
      # @param same_call [Array<Mapper::Route>] the routes its route call defines on its path
      # @return [Array<Solargraph::Pin::Method>]
      def helper_pins(route, same_call)
        if route.kind == :proxy
          closure = module_pin(route.location.filename, PROXY_MODULE)
          return [Util.build_public_method(closure, route.name, types: [PROXY_TYPE], location: route.location,
                                                                comments: "The route proxy of #{route.to}.")]
        end

        closure = module_pin(route.location.filename)
        comments = documentation(route, same_call)
        %w[path url].map do |suffix|
          method = Solargraph::Pin::Method.new(
            name: "#{route.name}_#{suffix}", closure: closure, scope: :instance, location: route.location,
            comments: "#{comments}\n@return [String]"
          )
          method.parameters.concat(parameters(route, method))
          method
        end
      end

      # @param route [Mapper::Route]
      # @param method [Solargraph::Pin::Method]
      # @return [Array<Solargraph::Pin::Parameter>]
      def parameters(route, method)
        params = route.segment_keys.map do |key|
          Solargraph::Pin::Parameter.new(name: key, decl: :optarg, closure: method, asgn_code: 'nil', comments: '')
        end
        params << Solargraph::Pin::Parameter.new(name: 'options', decl: :kwrestarg, closure: method, comments: '')
      end

      # @param route [Mapper::Route]
      # @return [Array(String, Integer, Integer, String, nil)] the routes call's file and position, and the route's path
      def call_key(route)
        start = route.location.range.start
        [route.location.filename, start.line, start.character, route.path]
      end

      # The verb, path pattern and `controller#action` of each route the helper's route call defines on its path.
      #
      # @param route [Mapper::Route]
      # @param same_call [Array<Mapper::Route>]
      # @return [String]
      def documentation(route, same_call)
        return 'A custom URL helper defined with `direct`.' if route.kind == :direct

        lines = same_call.map { |other| "    #{other.verbs.join('|').ljust(6)} #{other.path} #{other.to}".rstrip }
        "Named route `#{route.name}`:\n\n#{lines.uniq.join("\n")}\n"
      end
    end
  end
end
