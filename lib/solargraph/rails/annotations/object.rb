class Object
  # @return [self, nil]
  def presence; end

  # @return [self, nil]
  def presence_in(x); end

  # https://github.com/ruby/rbs/pull/3226
  # @param url [String]
  # @return [String]
  def self.yaml_tag(url); end
end

# @!override Object#present?
#   @return [Boolean]

# Boolean, not true/false: Method, UnboundMethod and Singleton return
# false, Numeric#html_safe? returns true.
# @!override Object#duplicable?
#   @return [Boolean]
# @!override Object#html_safe?
#   @return [Boolean]
# @!override Numeric#html_safe?
#   @return [Boolean]
# @!override Numeric#blank?
#   @return [Boolean]
