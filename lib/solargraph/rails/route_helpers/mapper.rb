module Solargraph
  module Rails
    class RouteHelpers
      # Reads an app's named routes from its routes DSL without booting Rails. It evaluates the literal arguments of
      # the DSL calls in `Rails.application.routes.draw`, with the naming rules of
      # ActionDispatch::Routing::Mapper (actionpack's action_dispatch/routing/mapper.rb), whose method names it uses.
      # A call whose naming arguments aren't literals is skipped, with its block.
      class Mapper # rubocop:disable Metrics/ClassLength
        # A route the DSL defines. Rails names a route only when it can (Mapper#name_for_action).
        #
        # @param name [String, nil]
        # @param verbs [Array<String>]
        # @param path [String, nil] the path pattern, e.g. '/posts/:id(.:format)'
        # @param to [String, nil] e.g. 'posts#show'
        # @param location [Solargraph::Location]
        # @param kind [Symbol] :route, :direct, or :proxy for a mounted engine's route proxy
        Route = Struct.new(:name, :verbs, :path, :to, :location, :kind, keyword_init: true) do
          # The dynamic segments a path helper needs, i.e. those outside optional parentheses.
          #
          # @return [Array<String>]
          def segment_keys
            return [] unless path

            required = path.dup
            nil while required.gsub!(/\([^()]*\)/, '')
            required.scan(/[:*](\w+)/).flatten
          end
        end

        # Options that change a route's name or path; a call is skipped when one of them isn't a literal
        NAMING_OPTIONS = %i[
          as path module controller action only except on param shallow shallow_path shallow_prefix concerns at
          path_names format
        ].freeze

        VERBS = %i[get post put patch delete options connect].freeze
        DSL_METHODS = %i[
          resources resource namespace scope controller constraints defaults shallow member collection new nested match root
          draw concern concerns direct mount
        ].freeze
        RESOURCE_OPTIONS = %i[as controller path only except param concerns].freeze
        CANONICAL_ACTIONS = %w[index create new show update destroy].freeze
        VALID_ON_OPTIONS = %i[new collection member].freeze
        SCOPE_OPTIONS = %i[path shallow_path as shallow_prefix module controller action path_names shallow via format to]
                        .freeze
        OPTIONAL_FORMAT_REGEX = %r{(?:\(\.:format\)+|\.:format|/)\Z}.freeze

        # @param root [String] the app's root directory
        # @param sources [Hash{String => String}] code of routes files to read instead of the files on disk
        def initialize(root, sources = {})
          @root = root
          @sources = sources
        end

        # @return [Array<Route>] every route, named or not, in definition order
        def routes
          @routes = []
          @names = Set.new
          @concerns = {}
          @expanding = Set.new
          @scope = Scope.new(path_names: { new: 'new', edit: 'edit' })
          file = File.join(@root, 'config/routes.rb')
          draw_blocks(parse(file)).each { |body| within_file(file) { eval_body(body) } }
          @routes
        end

        private

        # @param file [String]
        # @return [::Parser::AST::Node, nil]
        def parse(file)
          code = @sources.fetch(file) { File.exist?(file) ? File.read(file) : nil }
          return nil unless code

          NodeParser.parse_with_comments(code, file).first
        end

        # Solargraph::Range.from_node returns nil for Parser nodes on Solargraph 0.50 and earlier
        #
        # @param node [::Parser::AST::Node]
        # @return [Solargraph::Range]
        def range_of(node)
          Solargraph::Range.from_expr(node.loc.expression)
        end

        # The bodies of the app's `Rails.application.routes.draw do ... end` blocks. Engines' route sets are skipped.
        #
        # @param node [::Parser::AST::Node, nil]
        # @return [Array<::Parser::AST::Node>]
        def draw_blocks(node)
          return [] unless node.is_a?(::Parser::AST::Node)
          return node.children.flat_map { |child| draw_blocks(child) } if node.type == :begin
          return [] unless node.type == :block

          call, _args, body = node.children
          receiver, method = call.children
          return [] unless call.type == :send && method == :draw && app_routes?(receiver)

          [body].compact
        end

        # @param node [::Parser::AST::Node, nil]
        # @return [Boolean]
        def app_routes?(node)
          return false unless node.is_a?(::Parser::AST::Node) && node.type == :send && node.children[1] == :routes

          owner = node.children[0]
          return false unless owner.is_a?(::Parser::AST::Node)
          return owner.children[1] == :Application if owner.type == :const

          owner.type == :send && owner.children[1] == :application && Literal.value(owner.children[0]) == Literal::Const.new('Rails')
        end

        # @param file [String]
        # @yieldreturn [void]
        # @return [void]
        def within_file(file)
          saved = @file
          @file = file
          yield
        ensure
          @file = saved
        end

        # @param node [::Parser::AST::Node, nil]
        # @return [void]
        def eval_body(node)
          return unless node.is_a?(::Parser::AST::Node)

          case node.type
          when :begin, :kwbegin then node.children.each { |child| eval_body(child) }
          when :if then node.children[1..].each { |child| eval_body(child) }
          when :block, :numblock then eval_call(node.children[0], node.children[2])
          when :send then eval_call(node, nil)
          end
        end

        # @param call [::Parser::AST::Node]
        # @param body [::Parser::AST::Node, nil]
        # @return [void]
        def eval_call(call, body)
          receiver, method, *arg_nodes = call.children
          return unless call.type == :send && receiver.nil? && dsl?(method)

          args = arg_nodes.reject { |arg| arg.type == :block_pass }.map { |arg| Literal.value(arg) }
          return if args.any? { |arg| !readable?(arg) }

          saved = @location
          @location = Solargraph::Location.new(@file, range_of(call))
          block = body && proc { eval_body(body) }
          dispatch(method, args, body, &block)
        rescue StandardError => e
          Solargraph.logger.warn("solargraph-rails skipped a route at #{@file}: #{e.message}")
        ensure
          @location = saved
        end

        # @param method [Symbol]
        # @return [Boolean]
        def dsl?(method)
          VERBS.include?(method) || DSL_METHODS.include?(method)
        end

        # @param arg [Object]
        # @return [Boolean]
        def readable?(arg)
          return false if arg.equal?(Literal::UNKNOWN)
          return arg.all? { |item| readable?(item) } if arg.is_a?(Array)
          return NAMING_OPTIONS.none? { |key| arg[key].equal?(Literal::UNKNOWN) } if arg.is_a?(Hash)

          true
        end

        # @param method [Symbol]
        # @param args [Array<Object>]
        # @param body [::Parser::AST::Node, nil]
        # @return [void]
        def dispatch(method, args, body, &block)
          case method
          when *VERBS then map_method(method == :connect ? %i[get connect] : method, args, &block)
          when :new then new_scope(&block)
          when :match then match(*args, &block)
          when :concern then concern(args[0], body)
          when :constraints, :defaults then yield if block
          else send(method, *args, &block)
          end
        end

        # @param args [Array<Object>]
        # @return [Hash{Symbol => Object}]
        def extract_options!(args)
          args.last.is_a?(Hash) ? args.pop : {}
        end

        # @return [Boolean] whether config/application.rb sets `config.api_only = true`
        def api_only?
          return @api_only if defined?(@api_only)

          application = File.join(@root, 'config/application.rb')
          @api_only = File.exist?(application) && File.read(application).match?(/^\s*config\.api_only\s*=\s*true/)
        end

        # Mapper::Base#mount, for mounts with an `as:` name
        #
        # @return [void]
        def mount(app, options = nil)
          if options
            path = options[:at]
          elsif app.is_a?(Hash)
            options = app
            app, path = options.find { |key, _| key.is_a?(Literal::Const) }
          end
          return unless app.is_a?(Literal::Const) && path.is_a?(String) && options[:as]

          target_as = name_for_action(options[:as], path)
          match(path, { to: app.name, via: :all, anchor: false, format: false }.merge(options.reject { |key, _| [:at, app].include?(key) }))
          return unless target_as && app.name.end_with?('Engine')

          @routes << Route.new(name: target_as, verbs: [], path: nil, to: app.name, location: @location, kind: :proxy)
        end

        # Mapper::HttpHelpers#map_method
        #
        # @return [void]
        def map_method(method, args, &block)
          options = extract_options!(args)
          options[:via] = method
          match(*args, options, &block)
        end

        # Mapper::Scoping#scope
        #
        # @return [void]
        def scope(*args)
          options = extract_options!(args)
          scope = {}
          options[:path] = args.flatten.join('/') if args.any?

          unless @scope.nested?
            options[:shallow_path] ||= options[:path] if options.key?(:path)
            options[:shallow_prefix] ||= options[:as] if options.key?(:as)
          end
          scope[:action_options] = { only: options.delete(:only), except: options.delete(:except) } if options.key?(:only) || options.key?(:except)
          SCOPE_OPTIONS.each do |option|
            scope[option] = merge_scope(option, @scope[option], options[option]) if options.key?(option)
          end

          with_scope(@scope.new(scope)) { yield if block_given? }
        end

        # Mapper::Scoping#merge_*_scope
        #
        # @return [Object]
        def merge_scope(option, parent, child)
          case option
          when :path, :shallow_path then normalize_path("#{parent}/#{child}")
          when :as, :shallow_prefix then parent ? "#{parent}_#{child}" : child
          when :module then parent ? "#{parent}/#{child}" : child
          when :path_names then (parent || {}).merge(child)
          when :shallow then child ? true : false
          else child
          end
        end

        # @param scope [Scope]
        # @return [void]
        def with_scope(scope)
          saved = @scope
          @scope = scope
          yield
        ensure
          @scope = saved
        end

        # Mapper::Scoping#controller
        #
        # @return [void]
        def controller(controller, &block)
          with_scope(@scope.new(controller: controller), &block)
        end

        # Mapper::Scoping#namespace, with Mapper::Resources#namespace nesting it in a resource
        #
        # @return [void]
        def namespace(path, options = {}, &block)
          return nested { namespace(path, options, &block) } if @scope.resource_scope?

          path = path.to_s
          defaults = {
            module: path,
            as: options.fetch(:as, path),
            shallow_path: options.fetch(:path, path),
            shallow_prefix: options.fetch(:as, path)
          }
          path_scope(options.key?(:path) ? options[:path] : path) do
            scope(defaults.merge(options.reject { |key, _| key == :path }), &block)
          end
        end

        # Mapper::Resources#resource
        #
        # @return [void]
        def resource(*resources, &block)
          options = extract_options!(resources)
          return if apply_common_behavior_for(:resource, resources, options, &block)

          with_scope_level(:resource) do
            options = apply_action_options(:resource, options)
            resource_scope(SingletonResource.new(resources.pop, api_only?, @scope[:shallow], options)) do
              yield if block
              concerns(*Array(options[:concerns])) if options[:concerns]
              new_scope { map_method(:get, [:new]) } if parent_resource.actions.include?(:new)
              set_member_mappings_for_resource
              collection { map_method(:post, [:create]) } if parent_resource.actions.include?(:create)
            end
          end
        end

        # Mapper::Resources#resources
        #
        # @return [void]
        def resources(*resources, &block)
          options = extract_options!(resources)
          return if apply_common_behavior_for(:resources, resources, options, &block)

          with_scope_level(:resources) do
            options = apply_action_options(:resources, options)
            resource_scope(Resource.new(resources.pop, api_only?, @scope[:shallow], options)) do
              yield if block
              concerns(*Array(options[:concerns])) if options[:concerns]
              collection do
                map_method(:get, [:index]) if parent_resource.actions.include?(:index)
                map_method(:post, [:create]) if parent_resource.actions.include?(:create)
              end
              new_scope { map_method(:get, [:new]) } if parent_resource.actions.include?(:new)
              set_member_mappings_for_resource
            end
          end
        end

        # Mapper::Resources#set_member_mappings_for_resource
        #
        # @return [void]
        def set_member_mappings_for_resource
          actions = parent_resource.actions
          member do
            map_method(:get, [:edit]) if actions.include?(:edit)
            map_method(:get, [:show]) if actions.include?(:show)
            if actions.include?(:update)
              map_method(:patch, [:update])
              map_method(:put, [:update])
            end
            map_method(:delete, [:destroy]) if actions.include?(:destroy)
          end
        end

        # Mapper::Resources#apply_common_behavior_for
        #
        # @return [Boolean] whether it mapped the resources itself
        def apply_common_behavior_for(method, resources, options, &block) # rubocop:disable Naming/PredicateMethod
          if resources.length > 1
            resources.each { |name| send(method, name, options.dup, &block) }
            return true
          end
          if options[:shallow]
            shallow { send(method, resources.pop, options.reject { |key, _| key == :shallow }, &block) }
            return true
          end
          if @scope.resource_scope?
            nested { send(method, resources.pop, options, &block) }
            return true
          end

          scope_options = options.reject { |key, _| RESOURCE_OPTIONS.include?(key) }
          return false if scope_options.empty?

          scope(scope_options) { send(method, resources.pop, options.slice(*RESOURCE_OPTIONS), &block) }
          true
        end

        # Mapper::Resources#apply_action_options: a scope's `only:`/`except:` for the resources inside it
        #
        # @return [Hash{Symbol => Object}]
        def apply_action_options(method, options)
          return options if options[:only] || options[:except]
          return options unless @scope[:action_options]

          actions = (method == :resource ? SingletonResource : Resource).default_actions(api_only?)
          scoped = @scope[:action_options].dup
          scoped[:only] = Array(scoped[:only]).map(&:to_sym) & actions if scoped[:only]
          scoped[:except] = Array(scoped[:except]).map(&:to_sym) & actions if scoped[:except]
          options.merge(scoped)
        end

        # @return [Resource, nil]
        def parent_resource
          @scope[:scope_level_resource]
        end

        # @param kind [Symbol]
        # @return [void]
        def with_scope_level(kind, &block)
          with_scope(@scope.new_level(kind), &block)
        end

        # Mapper::Resources#resource_scope
        #
        # @return [void]
        def resource_scope(resource, &block)
          with_scope(@scope.new(scope_level_resource: resource)) { controller(resource.controller, &block) }
        end

        # Mapper::Resources#collection
        #
        # @return [void]
        def collection(&block)
          return unless @scope.resource_scope?

          with_scope_level(:collection) { path_scope(parent_resource.collection_scope, &block) }
        end

        # Mapper::Resources#member
        #
        # @return [void]
        def member(&block)
          return unless @scope.resource_scope?

          with_scope_level(:member) do
            if shallow?
              shallow_scope { path_scope(parent_resource.member_scope, &block) }
            else
              path_scope(parent_resource.member_scope, &block)
            end
          end
        end

        # Mapper::Resources#new
        #
        # @return [void]
        def new_scope(&block)
          return unless @scope.resource_scope?

          with_scope_level(:new) { path_scope(parent_resource.new_scope(action_path(:new)), &block) }
        end

        # Mapper::Resources#nested
        #
        # @return [void]
        def nested(&block)
          return unless @scope.resource_scope?

          with_scope_level(:nested) do
            if shallow? && shallow_nesting_depth >= 1
              shallow_scope { path_scope(parent_resource.nested_scope) { scope(nested_options, &block) } }
            else
              path_scope(parent_resource.nested_scope) { scope(nested_options, &block) }
            end
          end
        end

        # @return [Hash{Symbol => Object}]
        def nested_options
          { as: parent_resource.member_name }
        end

        # Mapper::Resources#shallow
        #
        # @return [void]
        def shallow(&block)
          with_scope(@scope.new(shallow: true), &block)
        end

        # @return [Boolean]
        def shallow?
          !parent_resource.singleton? && @scope[:shallow] ? true : false
        end

        # @return [Integer]
        def shallow_nesting_depth
          @scope.count { |node| node.frame[:scope_level_resource]&.shallow? }
        end

        # @return [void]
        def shallow_scope(&block)
          with_scope(@scope.new(as: @scope[:shallow_prefix], path: @scope[:shallow_path]), &block)
        end

        # @return [void]
        def path_scope(path, &block)
          with_scope(@scope.new(path: merge_scope(:path, @scope[:path], path)), &block)
        end

        # Mapper::Resources#draw: the routes of config/routes/<name>.rb, as if written in place
        #
        # @return [void]
        def draw(name)
          file = File.join(@root, 'config/routes', "#{name}.rb")
          expanding([:draw, file]) { within_file(file) { eval_body(parse(file)) } }
        end

        # Runs the block unless it is already running for the key, so a file drawing itself or a concern using itself
        # doesn't recurse.
        #
        # @param key [Array]
        # @return [void]
        def expanding(key)
          return unless @expanding.add?(key)

          begin
            yield
          ensure
            @expanding.delete(key)
          end
        end

        # Mapper::Concerns#concern
        #
        # @param name [Symbol]
        # @param body [::Parser::AST::Node, nil]
        # @return [void]
        def concern(name, body)
          @concerns[name] = [body, @file] if body
        end

        # Mapper::Concerns#concerns
        #
        # @return [void]
        def concerns(*names)
          extract_options!(names)
          names.flatten.each do |name|
            body, file = @concerns[name]
            expanding([:concern, name]) { within_file(file) { eval_body(body) } } if body
          end
        end

        # Mapper::CustomUrls#direct, which only works outside any scope
        #
        # @return [void]
        def direct(name, _options = {})
          return unless @scope.root?

          @routes << Route.new(name: name.to_s, verbs: [], path: nil, to: nil, location: @location, kind: :direct)
        end

        # Mapper::Resources#root
        #
        # @return [void]
        def root(path = nil, options = {})
          if path.is_a?(String)
            options = options.merge(to: path)
          elsif path.is_a?(Hash) && options.empty?
            options = path
          else
            return
          end

          if @scope.resources?
            with_scope_level(:root) { path_scope(parent_resource.path) { match_root_route(options) } }
          else
            match_root_route(options)
          end
        end

        # @return [void]
        def match_root_route(options)
          match('/', { as: :root, via: :get }.merge(options))
        end

        # Mapper::Resources#match
        #
        # @return [void]
        def match(path, *rest)
          if rest.empty? && path.is_a?(Hash)
            options = path
            path, to = options.find { |key, _| key.is_a?(String) }
            return if path.nil?

            options = options.reject { |key, _| key == path }
            case to
            when Symbol then options[:action] = to
            when String then to.include?('#') ? options[:to] = to : options[:controller] = to
            end
            paths = [path]
          else
            options = rest.last.is_a?(Hash) ? rest.pop : {}
            paths = [path] + rest
          end
          map_match(paths, options.transform_keys(&:to_sym))
        end

        # Mapper::Resources#map_match
        #
        # @return [void]
        def map_match(paths, options)
          return if options[:on] && !VALID_ON_OPTIONS.include?(options[:on])

          options = options.dup
          options[:to] ||= @scope[:to] if @scope[:to]
          options[:to] ||= "#{@scope[:controller]}##{@scope[:action]}" if @scope[:controller] && @scope[:action]
          controller = options.delete(:controller) || @scope[:controller]
          option_path = options.delete(:path)
          to = options.delete(:to)
          via = Array(options.key?(:via) ? options.delete(:via) : @scope[:via])
          formatted = options.key?(:format) ? options.delete(:format) : @scope[:format]

          paths.each do |path|
            if path.is_a?(String)
              route_to = get_to_from_path(path, to, options[:action])
              decomposed_match(path, controller, options.dup, path, route_to, via, formatted)
            elsif path.is_a?(Symbol)
              decomposed_match(path, controller, options.dup, option_path, to, via, formatted)
            end
          end
        end

        # @return [String, nil]
        def get_to_from_path(path, to, action)
          return to if to || action

          path_without_format = path.sub(/\(\.:format\)$/, '')
          return unless %r{^/?[-\w]+/[-\w/]+$}.match?(path_without_format)

          path_without_format.delete_prefix('/').sub(%r{/([^/]*)$}, '#\1').tr('-', '_')
        end

        # Mapper::Resources#decomposed_match
        #
        # @return [void]
        def decomposed_match(path, controller, options, option_path, to, via, formatted)
          on = options.delete(:on)
          if on
            send(on == :new ? :new_scope : on) { decomposed_match(path, controller, options, option_path, to, via, formatted) }
          elsif @scope.scope_level == :resources
            nested { decomposed_match(path, controller, options, option_path, to, via, formatted) }
          elsif @scope.scope_level == :resource
            member { decomposed_match(path, controller, options, option_path, to, via, formatted) }
          else
            add_route(path, controller, options, option_path, to, via, formatted)
          end
        end

        # Mapper::Resources#add_route
        #
        # @return [void]
        def add_route(action, controller, options, option_path, to, via, formatted)
          path = path_for_action(action, option_path)
          return if path.to_s.empty?

          action = action.to_s
          default_action = options.delete(:action) || @scope[:action]
          if %r{^[\w\-/]+$}.match?(action)
            default_action ||= action.tr('-', '_') unless action.include?('/')
          else
            action = nil
          end

          as = if options.key?(:as) && !options[:as]
                 nil
               else
                 name_for_action(options.delete(:as), action)
               end
          as = nil if as && @names.include?(as)
          @names << as if as
          @routes << Route.new(
            name: as, verbs: (via - [:all]).map { |verb| verb.to_s.upcase }, path: format_path(normalize_path(path), formatted),
            to: endpoint(to, controller, default_action), location: @location, kind: :route
          )
        end

        # The `controller#action` a route goes to (Mapping#normalize_options!, #add_controller_module)
        #
        # @return [String, nil]
        def endpoint(to, controller, action)
          return to if to.is_a?(String) && to.match?(/\A[A-Z]/)

          if to.is_a?(String) && to.include?('#')
            controller, action = to.split('#', 2)
          elsif to.is_a?(String) || to.is_a?(Symbol)
            action = to
          end
          return unless controller && action

          controller = controller.to_s
          mod = @scope[:module]
          controller = controller.start_with?('/') ? controller[1..] : [mod, controller].compact.join('/') if mod
          "#{controller}##{action}"
        end

        # @return [String]
        def path_for_action(action, path)
          return "#{@scope[:path]}/#{path}" if path
          return @scope[:path].to_s if canonical_action?(action)

          "#{@scope[:path]}/#{action_path(action)}"
        end

        # @return [Boolean]
        def canonical_action?(action)
          @scope.resource_method_scope? && CANONICAL_ACTIONS.include?(action.to_s)
        end

        # @return [String]
        def action_path(name)
          (@scope[:path_names] || {})[name.to_sym] || name.to_s
        end

        # @return [String, nil]
        def prefix_name_for_action(as, action)
          prefix = if as
                     as
                   elsif !canonical_action?(action)
                     action
                   end
          return unless prefix && prefix != '/' && !prefix.to_s.empty?

          normalize_name(prefix.to_s.tr('-', '_'))
        end

        # Mapper::Resources#name_for_action. A route without `as:` gets no name when its name is taken.
        #
        # @return [String, nil]
        def name_for_action(as, action)
          prefix = prefix_name_for_action(as, action)
          name_prefix = @scope[:as]
          if parent_resource
            return unless as || action

            collection_name = parent_resource.collection_name
            member_name = parent_resource.member_name
          end

          candidate = @scope.action_name(name_prefix, prefix, collection_name, member_name)
                            .map(&:to_s).reject(&:empty?).join('_')
          return if candidate.empty?
          return candidate unless as.nil?

          candidate if candidate.match?(/\A[_a-z]/i) && !@names.include?(candidate)
        end

        # Journey::Router::Utils.normalize_path and Mapper.normalize_path
        #
        # @return [String]
        def normalize_path(path)
          path = "/#{path}".squeeze('/')
          path = path.delete_suffix('/') unless path == '/'
          path.gsub(%r{/(\(+)/?}, '\1/')
        end

        # @return [String]
        def normalize_name(name)
          normalize_path(name)[1..].tr('/', '_')
        end

        # Mapping.normalize_path
        #
        # @return [String]
        def format_path(path, formatted)
          return "#{path}.:format" if formatted == true
          return path if formatted == false || path.match?(OPTIONAL_FORMAT_REGEX)

          "#{path}(.:format)"
        end
      end
    end
  end
end
