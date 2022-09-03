module Solargraph
  module Rails
    class Walker
      class Hook
        attr_reader :args, :proc, :node_type
        def initialize(node_type, args, &block)
          @node_type = node_type
          @args = args
          @proc = Proc.new(&block)
        end
      end

      # https://github.com/castwide/solargraph/issues/522
      def self.normalize_ast(source)
        ast = source.node

        if ast.is_a?(::Parser::AST::Node)
          ast
        else
          NodeParser.parse_with_comments(source.code, source.filename)
        end
      end

      def self.from_source(source)
        self.new(*self.normalize_ast(source))
      end

      attr_reader :ast, :comments
      def initialize(ast, comments = {})
        @comments = comments
        @ast = ast
        @hooks = Hash.new([])
      end

      def on(node_type, args = [], &block)
        @hooks[node_type] << Hook.new(node_type, args, &block)
      end

      def walk
        @ast.is_a?(Array) ? @ast.each { |node| traverse(node) } : traverse(@ast)
      end

      private

      def traverse(node)
        return unless node.is_a?(::Parser::AST::Node)

        @hooks[node.type].each { |hook| try_match(node, hook) }

        node.children.each { |child| traverse(child) }
      end

      def try_match(node, hook)
        return unless matches?(node, hook)

        if hook.proc.arity == 1
          hook.proc.call(node)
        elsif hook.proc.arity == 2
          walker = Walker.new(node)
          hook.proc.call(node, walker)
          walker.walk
        end
      end

      def matches?(node, hook)
        return unless node.type == hook.node_type
        return unless node.children
        return true if hook.args.empty?

        if node.children.first.is_a?(::Parser::AST::Node)
          node.children.any? do |child|
            child.is_a?(::Parser::AST::Node) &&
              match_children(hook.args[1..-1], child.children)
          end
        else
          match_children(hook.args, node.children)
        end
      end

      def match_children(args, children)
        args.each_with_index.all? do |arg, i|
          if children[i].is_a?(::Parser::AST::Node)
            children[i].type == arg
          else
            children[i] == arg
          end
        end
      end
    end
  end
end
