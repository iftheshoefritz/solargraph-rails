require 'date'
require 'active_support/core_ext'

class Date
  # @param form [Symbol]
  # @return [Time]
  def to_time(form = :local); end

  # @return [Rational, self]
  def -(other); end

  # @return [self]
  def +(other); end

  # @return [String]
  def readable_inspect; end

  # @param other [Object]
  # @return [Integer, nil]
  def compare_with_coercion(other); end

  # @return [-1, 0, 1, nil]
  def <=>(other); end

  # @return [::Time]
  def to_time; end

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

  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

# @!override Date#blank?
#   @return [Boolean]
# @!override Date#acts_like_date?
#   @return [Boolean]
# @!override DateTime#blank?
#   @return [Boolean]
# @!override DateTime#acts_like_date?
#   @return [Boolean]
# @!override DateTime#acts_like_time?
#   @return [Boolean]
