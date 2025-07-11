module ActionText
  module Attribute
    # @param name [String, Symbol]
    # @param encrypted [Boolean]
    # @param strict_loading [Boolean]
    # @return [void]
    def self.has_rich_text(name, encrypted = false, strict_loading = false); end
    # @return [Array<String>]
    def self.rich_text_association_names; end
  end
end
