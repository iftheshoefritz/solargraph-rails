module Turbo
  module Broadcastable
    module ClassMethods
      def broadcasts_to(stream, inserts_by: :append, target: broadcast_target_default, **rendering); end
      def broadcasts(stream = model_name.plural, inserts_by: :append, target: broadcast_target_default, **rendering); end
      def broadcasts_refreshes_to(stream); end
      def broadcasts_refreshes(stream = model_name.plural); end
      def broadcast_target_default; end
      # @yield
      def suppressing_turbo_broadcasts; end
      # @return [Boolean]
      def suppressed_turbo_broadcasts?; end
    end

    def broadcast_remove_to(*streamables, target: self, **rendering); end
    def broadcast_remove(**rendering); end
    def broadcast_replace_to(*streamables, **rendering); end
    def broadcast_replace(**rendering); end
    def broadcast_update_to(*streamables, **rendering); end
    def broadcast_update(**rendering); end
    def broadcast_before_to(*streamables, target: nil, targets: nil, **rendering); end
    def broadcast_after_to(*streamables, target: nil, targets: nil, **rendering); end
    def broadcast_append_to(*streamables, target: broadcast_target_default, **rendering); end
    def broadcast_append(target: broadcast_target_default, **rendering); end
    def broadcast_prepend_to(*streamables, target: broadcast_target_default, **rendering); end
    def broadcast_prepend(target: broadcast_target_default, **rendering); end
    def broadcast_refresh_to(*streamables, **attributes); end
    def broadcast_refresh; end
    def broadcast_action_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering); end
    def broadcast_action(action, target: broadcast_target_default, attributes: {}, **rendering); end
    def broadcast_replace_later_to(*streamables, **rendering); end
    def broadcast_replace_later(**rendering); end
    def broadcast_update_later_to(*streamables, **rendering); end
    def broadcast_update_later(**rendering); end
    def broadcast_append_later_to(*streamables, target: broadcast_target_default, **rendering); end
    def broadcast_append_later(target: broadcast_target_default, **rendering); end
    def broadcast_prepend_later_to(*streamables, target: broadcast_target_default, **rendering); end
    def broadcast_prepend_later(target: broadcast_target_default, **rendering); end
    def broadcast_refresh_later_to(*streamables, **attributes); end
    def broadcast_refresh_later; end
    def broadcast_action_later_to(*streamables, action:, target: broadcast_target_default, attributes: {}, **rendering); end
    def broadcast_action_later(action:, target: broadcast_target_default, attributes: {}, **rendering); end
    def broadcast_render(**rendering); end
    def broadcast_render_to(*streamables, **rendering); end
    def broadcast_render_later(**rendering); end
    def broadcast_render_later_to(*streamables, **rendering); end
  end
end
