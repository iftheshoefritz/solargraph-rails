require 'date'
require 'active_support/core_ext'

class Date
  # @return [String]
  def readable_inspect; end

  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end

  # Delete once https://github.com/apiology/gem_rbs_collection/pull/11 lands.
  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

class DateTime < Date
  # @param other [Numeric, ActiveSupport::Duration]
  # @return [self]
  def +(other); end

  # @param other [Numeric, Date, ActiveSupport::Duration]
  # @return [Rational, self]
  def -(other); end

  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end

  # @param other [Object]
  # @return [Integer, nil]
  def <=>(other); end

  # @return [String]
  def readable_inspect; end

  # Delete once https://github.com/apiology/gem_rbs_collection/pull/11 lands.
  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

# ActiveSupport returns a String; json's RBS types json/add's Hash-returning
# version, which Rails does not load: https://github.com/ruby/rbs/blob/v4.1.3/stdlib/json/0/json.rbs#L1456
# @!override Date#as_json
#   @return [String]
# @!override DateTime#as_json
#   @return [String]
