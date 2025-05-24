module Solargraph
  module Rails
    class Delegate
      def self.instance
        @instance ||= self.new
      end

      def self.supported?
        Solargraph::Pin.const_defined?(:DelegatedMethod)
      end

      def process(source_map, ns)
        return [] unless self.class.supported?
        return [] unless source_map.code.include?('delegate')

        walker = Walker.from_source(source_map.source)
        pins = []

        walker.on :send, [nil, :delegate] do |ast|
          next unless ast.children[-1].type == :hash

          methods = ast.children[2...-1].select { |c| c.type == :sym }

          delegate_node = Util.extract_option(ast, :to)
          next unless delegate_node

          chain = if delegate_node.type == :sym
            # `delegate ..., to: :bar` means call the #bar method to get the delegate object
            call = Solargraph::Source::Chain::Call.new(delegate_node.children[0].to_s)
            Solargraph::Source::Chain.new([call], delegate_node)
          else
            # for any other type of delegate, we create a chain from the AST node
            Solargraph::Parser::Legacy::NodeChainer.chain(delegate_node, ns.filename)
          end

          prefix_node = Util.extract_option(ast, :prefix)

          prefix = nil
          if prefix_node
            if prefix_node.type == :sym
              prefix = prefix_node.children[0]
            elsif prefix_node.type == :true && delegate_node.type == :sym
              prefix = delegate_node.children[0]
            end
          end

          location = Util.build_location(ast, ns.filename)
          methods.each do |meth|
            method_name = meth.children[0]
            pins << Solargraph::Pin::DelegatedMethod.new(
              closure: ns,
              scope: :instance,
              name: [prefix, method_name].select(&:itself).join("_"),
              node: meth,
              receiver: chain,
              receiver_method_name: method_name.to_s,
              location: location
            )
          end
        end

        walker.walk

        if pins.any?
          Solargraph.logger.debug(
            "[Rails][Delegate] added #{pins.map(&:name)} to #{ns.path}"
          )
        end

        pins
      end
    end
  end
end
