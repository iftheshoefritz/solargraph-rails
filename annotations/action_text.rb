module ActionText
  module Attribute
    # Move to a solargraph_before_<release> directory once https://github.com/castwide/solargraph/pull/1378 ships in a release.

    # @param name [String, Symbol]
    # @param encrypted [Boolean]
    # @param strict_loading [Boolean]
    # @return [void]
    def self.has_rich_text(name, encrypted = false, strict_loading = false); end
    # @return [Array<String>]
    def self.rich_text_association_names; end
  end
end
