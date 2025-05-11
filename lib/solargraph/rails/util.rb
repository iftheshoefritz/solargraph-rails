module Solargraph
  module Rails
    module Util
      def self.build_public_method(
        ns,
        name,
        params: {},
        parameters: [],
        comments: nil,
        types: nil,
        location: nil,
        attribute: false,
        scope: :instance
      )
        opts = {
          name: name,
          parameters: parameters,
          location: location,
          closure: ns,
          scope: scope,
          attribute: attribute
        }

        comments ||= begin
                       comments_arr = []
                       params.each do |name, types|
                         comments_arr << "@param [#{types.join(',')}] #{name}"
                       end
                       comments_arr << "\n@return [#{types.join(',')}]" if types
                       comments_arr.join("\n")
                     end

        opts[:comments] ||= comments

        m = Solargraph::Pin::Method.new(**opts)
        parameters = params.map do |name, type|
            Solargraph::Pin::Parameter.new(
              location: nil,
              closure: m,
              comments: '',
              name: name,
              presence: nil,
              decl: :arg,
              asgn_code: nil
            )
        end
        m.parameters.concat(parameters)
        m
      end

      def self.build_module_include(ns, module_name, location)
        Solargraph::Pin::Reference::Include.new(
          closure: ns,
          name: module_name,
          location: location
        )
      end

      def self.build_module_extend(ns, module_name, location)
        Solargraph::Pin::Reference::Extend.new(
          closure: ns,
          name: module_name,
          location: location
        )
      end

      def self.dummy_location(path)
        Solargraph::Location.new(
          File.expand_path(path),
          Solargraph::Range.from_to(0, 0, 0, 0)
        )
      end

      def self.build_location(ast, path)
        Solargraph::Location.new(
          File.expand_path(path),
          Solargraph::Range.from_to(
            ast.location.first_line,
            0,
            ast.location.last_line,
            ast.location.column
          )
        )
      end

      def self.method_return(path, type)
        Solargraph::Pin::Reference::Override.method_return(path, type)
      end

      # Extract the value of a given option from a :send syntax node.
      #
      # E.g. given an AST node for `foo(:bar, baz: qux)`, you can use
      # `extract_option(node, :baz)` to get the AST node for `qux`.
      #
      # @param call_node [Node]
      # @param option_name [Symbol]
      # @return [Node, nil]
      def self.extract_option(call_node, option_name)
        options = call_node.children[3..-1].find { |n| n.type == :hash }
        return unless options

        pair =
          options.children.find do |n|
            n.children[0] && n.children[0].deconstruct == [:sym, option_name]
          end
        return unless pair

        pair.children[1]
      end
    end
  end
end
