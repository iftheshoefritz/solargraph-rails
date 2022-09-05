module Solargraph
  module Rails
    class Walker
      class Hook
        attr_reader :node_type
        def initialize(node_type, args, &block)
          @node_type = node_type
          @args = args
          @proc = Proc.new(&block)
        end

        def visit(node)
          return unless matches?(node)

          if @proc.arity == 1
            @proc.call(node)
          elsif @proc.arity == 2
            walker = Walker.new(node)
            @proc.call(node, walker)
            walker.walk
          end
        end

        private

        def matches?(node)
          return unless node.type == node_type
          return unless node.children
          return true if @args.empty?

          a_child_matches = node.children.first.is_a?(::Parser::AST::Node) && node.children.any? do |child|
            child.is_a?(::Parser::AST::Node) &&
              match_children(child.children, @args[1..-1])
          end

          return true if a_child_matches

          match_children(node.children)
        end

        def match_children(children, args = @args)
          args.each_with_index.all? do |arg, i|
            if children[i].is_a?(::Parser::AST::Node)
              children[i].type == arg
            else
              children[i] == arg
            end
          end
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

        @hooks[node.type].each { |hook| hook.visit(node) }

        node.children.each { |child| traverse(child) }
      end
    end
  end
end
