module ActiveModel
  module Translation
    # @param options [Hash] options to customize the output
    # @param attribute [Symbol, String] the name of the attribute
    # @return [String]
    def human_attribute_name(attribute, options = {}); end
  end

  module Validations
    # @return [Boolean]
    def validate; end
  end
end
