module Solargraph
  module Rails
    module LoadHooks
      # Maps include, extend and prepend inside
      # ActiveSupport.on_load(:hook) { ... } onto the classes in CLASSES,
      # e.g. responders' include ActionController::RespondWith onto
      # ActionController::Base. Runs after Solargraph's own :send processor.
      class SendNode < Solargraph::Parser::NodeProcessor::Base
        include Solargraph::Parser::ParserGem::NodeMethods

        MIXINS = {
          'include' => Solargraph::Pin::Reference::Include,
          'extend' => Solargraph::Pin::Reference::Extend,
          'prepend' => Solargraph::Pin::Reference::Prepend
        }.freeze

        # Children were already processed by Solargraph's own :send processor.
        #
        # @return [Boolean]
        def process # rubocop:disable Naming/PredicateMethod -- overrides NodeProcessor::Base#process
          block = region.closure
          targets = block.is_a?(Solargraph::Pin::Block) ? hook_targets(block) : []
          map_mixin(block, targets) unless targets.empty?
          true
        end

        private

        # @param block [Solargraph::Pin::Block]
        # @param targets [Array<String>]
        # @return [void]
        def map_mixin(block, targets)
          return unless base?(node.children[0], block)

          reference_class = MIXINS[mixin_name]
          return unless reference_class

          mixin_args.each do |arg|
            next unless arg.is_a?(::Parser::AST::Node) && arg.type == :const

            location = get_node_location(arg)
            targets.each do |target|
              closure = Solargraph::Pin::Namespace.new(location: location, name: target, source: :parser)
              pins.push reference_class.new(location: location, closure: closure, name: unpack_name(arg),
                                            source: :parser)
            end
          end
        end

        # The method called, unwrapping send(:include, Foo).
        #
        # @return [String, nil]
        def mixin_name
          name = node.children[1].to_s
          return name unless name == 'send'

          keyword = node.children[2]
          keyword.children[0].to_s unless keyword.nil? || keyword.type != :sym
        end

        # @return [Array<::Parser::AST::Node>]
        def mixin_args
          node.children.drop(node.children[1] == :send ? 3 : 2)
        end

        # Only calls on the hook's base count: no receiver, self or the block parameter.
        #
        # @param receiver [::Parser::AST::Node, nil]
        # @param block [Solargraph::Pin::Block]
        # @return [Boolean]
        def base?(receiver, block)
          return true if receiver.nil? || receiver.type == :self
          return false unless receiver.type == :lvar

          param = block.parameters.first
          !param.nil? && param.name == receiver.children[0].to_s
        end

        # The classes the enclosing ActiveSupport.on_load block runs on.
        #
        # @param block [Solargraph::Pin::Block]
        # @return [Array<String>]
        def hook_targets(block)
          call = block.receiver
          return [] unless call.is_a?(::Parser::AST::Node) && call.type == :send && call.children[1] == :on_load

          owner = call.children[0]
          hook = call.children[2]
          return [] if owner.nil? || owner.type != :const
          return [] unless %w[ActiveSupport ::ActiveSupport].include?(unpack_name(owner))
          return [] if hook.nil? || hook.type != :sym

          CLASSES.fetch(hook.children[0], [])
        end
      end
    end
  end
end
