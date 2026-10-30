class Object
  # @return [self, nil]
  def presence; end

  # @return [self, nil]
  def presence_in(x); end
end

# @!override Object#present?
#   @return [Boolean]
# @!override Numeric#html_safe?
#   @return [Boolean]
# @!override Numeric#blank?
#   @return [Boolean]
