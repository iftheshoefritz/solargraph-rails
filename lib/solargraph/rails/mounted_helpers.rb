module Solargraph
  module Rails
    # Types the route helpers Rails adds to controllers with
    # RouteSet#define_mounted_helper, e.g. main_app. Rails writes them with a
    # string class_eval and includes them through a method call, so this reads
    # both facts from the Rails gems' syntax instead:
    #
    #   app.routes.define_mounted_helper(:main_app)  # railties
    #   ActiveSupport.on_load(:action_controller) do # actionpack
    #     include app.routes.mounted_helpers
    #   end
    class MountedHelpers
      MODULE = 'ActionDispatch::Routing::RouteSet::MountedHelpers'.freeze
      RETURN_TYPE = 'ActionDispatch::Routing::RoutesProxy'.freeze
      GEMS = %w[railties actionpack].freeze

      # Helpers and the classes including them, found in some source.
      class Scan
        # @return [Array<String>] names passed to define_mounted_helper
        attr_accessor :helpers

        # @return [Array<String>] classes whose on_load hooks include the helpers
        attr_accessor :targets

        # @return [Solargraph::Location, nil] the first define_mounted_helper call
        attr_accessor :location

        def initialize
          @helpers = []
          @targets = []
          @location = nil
        end
      end

      # Whether Solargraph exposes the gems it loaded.
      #
      # @return [Boolean]
      def self.supported?
        Solargraph::ApiMap.method_defined?(:external)
      end

      # @param code [String]
      # @param filename [String, nil]
      # @return [Scan]
      def self.scan(code, filename = nil)
        Scanner.new(filename).scan(Solargraph::Parser.parse(code, filename))
      end

      # @return [MountedHelpers]
      def self.instance
        @instance ||= new
      end

      # Method pins for the helpers on the class a method lookup is for.
      #
      # @param api_map [Solargraph::ApiMap]
      # @param rooted_tag [String]
      # @param scope [Symbol]
      # @return [Array<Solargraph::Pin::Method>]
      def object(api_map, rooted_tag, scope)
        return [] unless scope == :instance && self.class.supported?

        fqns = rooted_tag.delete_prefix('::').split('<').first
        found = scan_gems(api_map)
        return [] unless fqns == MODULE || found.targets.include?(fqns)

        closure = Solargraph::Pin::Namespace.new(name: MODULE, type: :module, location: found.location)
        found.helpers.map do |name|
          Util.build_public_method(closure, name, types: [RETURN_TYPE], location: found.location)
        end
      end

      private

      # @param api_map [Solargraph::ApiMap]
      # @return [Scan]
      def scan_gems(api_map)
        # Rescan only when Solargraph reloads the gems
        key = [api_map.external.object_id, api_map.external.generation]
        return @scan if @scan && @scan_key == key

        dirs = rails_gems(api_map).flat_map { |gem| gem.require_paths.map { |path| File.join(gem.full_path, path) } }
        @scan_key = key
        @scan = scan_dirs(dirs)
      end

      # @sg-ignore External#loaded_gems has no element type before
      #   https://github.com/apiology/solargraph/pull/173
      # @param api_map [Solargraph::ApiMap]
      # @return [Array<Solargraph::Metagem>]
      def rails_gems(api_map)
        # @sg-ignore External#loaded_gems has no element type before
        #   https://github.com/apiology/solargraph/pull/173
        api_map.external.loaded_gems.select { |gem| GEMS.include?(gem.name) }
      end

      # @param dirs [Array<String>]
      # @return [Scan]
      def scan_dirs(dirs)
        result = Scan.new
        dirs.flat_map { |dir| Dir.glob(File.join(dir, '**', '*.rb')) }.each do |file|
          code = File.read(file)
          next unless code.include?('mounted_helper')

          found = self.class.scan(code, file)
          result.helpers |= found.helpers
          result.targets |= found.targets
          result.location ||= found.location
        end
        result
      end

      # Walks one file's syntax tree.
      class Scanner
        include Solargraph::Parser::ParserGem::NodeMethods

        # @param filename [String, nil]
        def initialize(filename)
          @filename = filename
          @result = Scan.new
        end

        # @param node [::Parser::AST::Node, nil]
        # @return [Scan]
        def scan(node)
          return @result if node.nil?

          walk(node, [])
          @result
        end

        private

        # @param node [::Parser::AST::Node]
        # @param hooks [Array<String>] classes of the enclosing on_load block
        # @return [void]
        def walk(node, hooks)
          hooks = on_load_targets(node) || hooks if node.type == :block
          hooks = [] if %i[class module def defs].include?(node.type)
          visit_send(node, hooks) if node.type == :send
          node.children.each { |child| walk(child, hooks) if child.is_a?(::Parser::AST::Node) }
        end

        # @param node [::Parser::AST::Node]
        # @param hooks [Array<String>]
        # @return [void]
        def visit_send(node, hooks)
          receiver, method, arg = node.children
          return unless arg.is_a?(::Parser::AST::Node)

          if method == :define_mounted_helper && arg.type == :sym
            @result.helpers |= [arg.children[0].to_s]
            @result.location ||= get_node_location(node)
          elsif method == :include && receiver.nil? && arg.type == :send && arg.children[1] == :mounted_helpers
            @result.targets |= hooks
          end
        end

        # The classes an ActiveSupport.on_load block runs on.
        #
        # @param block [::Parser::AST::Node]
        # @return [Array<String>, nil]
        def on_load_targets(block)
          call, = block.children
          return nil unless call.is_a?(::Parser::AST::Node) && call.type == :send && call.children[1] == :on_load

          owner, _, hook = call.children
          return nil unless owner.is_a?(::Parser::AST::Node) && owner.type == :const
          return nil unless unpack_name(owner).delete_prefix('::') == 'ActiveSupport'
          return nil unless hook.is_a?(::Parser::AST::Node) && hook.type == :sym

          LoadHooks::CLASSES.fetch(hook.children[0], [])
        end

        # @param node [::Parser::AST::Node]
        # @return [Solargraph::Location, nil]
        def get_node_location(node)
          range = Solargraph::Range.from_node(node)
          Solargraph::Location.new(@filename, range) if @filename && range
        end
      end
    end
  end
end
