module ActiveStorage
  module Attached
    module Model
      # @return [void]
      def self.attachment_changes; end

      # @return [Boolean]
      def self.changed_for_autosave?; end

      # @param lock [BasicObject]
      # @return [self]
      def self.reload(lock = false); end
    end
  end
end
