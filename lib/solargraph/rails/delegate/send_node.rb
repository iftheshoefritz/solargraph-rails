module Solargraph
  module Rails
    class Delegate
      # Maps ActiveSupport's delegate :name, to: :target onto DelegatedMethod
      # pins in every file, gems included. Runs after Solargraph's own :send processor.
      class SendNode < Solargraph::Parser::NodeProcessor::Base
        include Solargraph::Parser::ParserGem::NodeMethods

        # Children were already processed by Solargraph's own :send processor.
        #
        # @return [Boolean]
        def process # rubocop:disable Naming/PredicateMethod -- overrides NodeProcessor::Base#process
          map_delegate if node.children[0].nil? && node.children[1] == :delegate
          true
        end

        private

        # @return [void]
        def map_delegate
          # A bare delegate call has no options to read
          return if node.children.length < 3

          to = word(Util.extract_option(node, :to))
          return if to.nil?

          prefix = prefix_for(Util.extract_option(node, :prefix), to)
          return if prefix.nil?

          receiver = receiver_chain(to)
          return if receiver.nil?

          visibility = true_node?(Util.extract_option(node, :private)) ? :private : region.visibility
          method_names.each do |name|
            pins.push Solargraph::Pin::DelegatedMethod.new(
              location: get_node_location(node),
              closure: region.closure,
              name: "#{prefix}#{name}",
              receiver: receiver,
              receiver_method_name: name,
              scope: region.scope || :instance,
              visibility: visibility,
              comments: comments_for(node),
              source: :parser
            )
          end
        end

        # Names passed to delegate, expanding a splatted constant assigned a
        # literal array in this file, e.g. delegate(*METHODS, to: :all).
        #
        # @return [Array<String>]
        def method_names
          node.children.drop(2).flat_map do |arg|
            next constant_words(arg.children[0]) if arg.type == :splat

            [word(arg)].compact
          end
        end

        # @param const_node [::Parser::AST::Node, nil]
        # @return [Array<String>]
        def constant_words(const_node)
          return [] if const_node.nil?
          return [] unless const_node.type == :const

          name = unpack_name(const_node)
          namespace = region.closure.full_context.namespace
          constant = pins.grep(Solargraph::Pin::Constant).find { |pin| pin.name == name && pin.namespace == namespace }
          array = literal_array(constant&.assignment)
          return [] if array.nil?

          array.children.filter_map { |item| word(item) }
        end

        # The array literal assigned, unwrapping [...].freeze.
        #
        # @param value [::Parser::AST::Node, nil]
        # @return [::Parser::AST::Node, nil]
        def literal_array(value)
          return nil if value.nil?
          return literal_array(value.children[0]) if value.type == :send && value.children[1] == :freeze

          value.type == :array ? value : nil
        end

        # The prefix ActiveSupport puts on delegated method names, or nil
        # when prefix: true has no method name to derive it from.
        #
        # @param option [::Parser::AST::Node, nil] the prefix: value
        # @param to [String]
        # @return [String, nil]
        def prefix_for(option, to)
          return '' if option.nil? || %i[false nil].include?(option.type)
          return (to.match?(/\A[a-z_]/) ? "#{to}_" : nil) if true_node?(option)

          prefix = word(option)
          prefix.nil? ? '' : "#{prefix}_"
        end

        # @param option [::Parser::AST::Node, nil]
        # @return [Boolean]
        def true_node?(option)
          option&.type == :true # rubocop:disable Lint/BooleanSymbol -- an AST node type
        end

        # @param subject [::Parser::AST::Node, nil] a symbol or string, e.g. :@records or "size"
        # @return [String, nil]
        def word(subject)
          return nil if subject.nil?
          return nil unless %i[sym str].include?(subject.type)

          subject.children[0].to_s
        end

        # Solargraph 0.60.4+ resolves an instance variable at the location it is read.
        #
        # @param name [String] e.g. "@records"
        # @return [Solargraph::Source::Chain::InstanceVariable]
        def ivar_link(name)
          link = Solargraph::Source::Chain::InstanceVariable
          args = link.instance_method(:initialize).arity == 3 ? [name, node, get_node_location(node)] : [name]
          link.new(*args)
        end

        # @param target [String] e.g. "records", "class", "@records" or "Foo.bar"
        # @return [Solargraph::Source::Chain, nil]
        def receiver_chain(target)
          link = if target.match?(/\A[a-z_]\w*[?!]?\z/)
                   # Includes keywords: ActiveSupport sends to: :class to self
                   Solargraph::Source::Chain::Call.new(target)
                 elsif target.match?(/\A@\w+\z/)
                   ivar_link(target)
                 end
          return Solargraph::Source::Chain.new([link]) if link

          filename = region.filename
          Solargraph::Parser::ParserGem::NodeChainer.chain(Solargraph::Parser.parse(target, filename), filename)
        rescue Solargraph::Parser::SyntaxError
          nil
        end
      end
    end
  end
end
