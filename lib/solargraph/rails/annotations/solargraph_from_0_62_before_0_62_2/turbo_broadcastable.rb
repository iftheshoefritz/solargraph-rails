module Turbo
  module Broadcastable
    module ClassMethods
      # @param stream [Symbol, Proc]
      # @param inserts_by [Symbol]
      # @param target [Object]
      # @param rendering [Hash{Symbol => Object}]
      # @return [void]
      def broadcasts_to(stream, inserts_by: :append, target: broadcast_target_default, **rendering); end

      # @param stream [Object]
      # @param inserts_by [Symbol]
      # @param target [Object]
      # @param rendering [Hash{Symbol => Object}]
      # @return [void]
      def broadcasts(stream = model_name.plural, inserts_by: :append, target: broadcast_target_default, **rendering); end

      # @param stream [Symbol, Proc]
      # @return [void]
      def broadcasts_refreshes_to(stream); end

      # @param stream [Object]
      # @return [void]
      def broadcasts_refreshes(stream = model_name.plural); end

      # @return [String]
      def broadcast_target_default; end

      # @generic T
      # @yieldreturn [generic<T>]
      # @return [generic<T>]
      def suppressing_turbo_broadcasts; end

      # @return [boolish]
      def suppressed_turbo_broadcasts?; end
    end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_remove_to(*streamables, target: self, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_remove(**rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_replace_to(*streamables, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_replace(**rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_update_to(*streamables, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_update(**rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param targets [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_before_to(*streamables, target: nil, targets: nil, **rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param targets [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_after_to(*streamables, target: nil, targets: nil, **rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_append_to(*streamables, target: broadcast_target_default, **rendering); end

    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_append(target: broadcast_target_default, **rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_prepend_to(*streamables, target: broadcast_target_default, **rendering); end

    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_prepend(target: broadcast_target_default, **rendering); end

    # @param streamables [Array<Object>]
    # @param attributes [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_refresh_to(*streamables, **attributes); end

    # @return [void]
    def broadcast_refresh; end

    # @param streamables [Array<Object>]
    # @param action [Symbol, String]
    # @param target [Object]
    # @param attributes [Hash{Symbol => Object}]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_action_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering); end

    # @param action [Symbol, String]
    # @param target [Object]
    # @param attributes [Hash{Symbol => Object}]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_action(action, target: broadcast_target_default, attributes: {}, **rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_replace_later_to(*streamables, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_replace_later(**rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_update_later_to(*streamables, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_update_later(**rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_append_later_to(*streamables, target: broadcast_target_default, **rendering); end

    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_append_later(target: broadcast_target_default, **rendering); end

    # @param streamables [Array<Object>]
    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_prepend_later_to(*streamables, target: broadcast_target_default, **rendering); end

    # @param target [Object]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_prepend_later(target: broadcast_target_default, **rendering); end

    # @param streamables [Array<Object>]
    # @param attributes [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_refresh_later_to(*streamables, **attributes); end

    # @return [void]
    def broadcast_refresh_later; end

    # @param streamables [Array<Object>]
    # @param action [Symbol, String]
    # @param target [Object]
    # @param attributes [Hash{Symbol => Object}]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_action_later_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering); end

    # @param action [Symbol, String]
    # @param target [Object]
    # @param attributes [Hash{Symbol => Object}]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_action_later(action:, target: broadcast_target_default, attributes: {}, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_render(**rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_render_to(*streamables, **rendering); end

    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_render_later(**rendering); end

    # @param streamables [Array<Object>]
    # @param rendering [Hash{Symbol => Object}]
    # @return [void]
    def broadcast_render_later_to(*streamables, **rendering); end
  end
end
