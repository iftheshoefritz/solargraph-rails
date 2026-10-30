class Object
  # https://github.com/ruby/rbs/pull/3226
  # @param url [String]
  # @return [String]
  def self.yaml_tag(url); end
end

# Boolean, not true/false: Method, UnboundMethod and Singleton return
# false, Numeric#html_safe? returns true.
# Delete once https://github.com/apiology/gem_rbs_collection/pull/<N> merges.
# @!override Object#duplicable?
#   @return [Boolean]
# @!override Object#html_safe?
#   @return [Boolean]
