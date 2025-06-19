module ActiveModel
  module Translation
    # @param options [Hash] options to customize the output
    # @param attribute [Symbol, String] the name of the attribute
    # @return [String]
    def human_attribute_name(attribute, options = {}); end
  end

  module Naming
    # @return [ActiveModel::Name] the model name for the class
    def model_name; end
  end
end
