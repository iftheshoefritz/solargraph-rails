require 'time'

class Time
  # @return [Boolean]
  def eql_with_coercion(other); end

  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end

  # Delete once https://github.com/ruby/gem_rbs_collection/pull/1121 lands.
  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

# ActiveSupport returns a String; json's RBS types json/add's Hash-returning
# version, which Rails does not load: https://github.com/ruby/rbs/blob/v4.1.3/stdlib/json/0/json.rbs#L1947
# @!override Time#as_json
#   @return [String]
