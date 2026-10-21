module Solargraph
  module Rails
    class MountedHelpers
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
