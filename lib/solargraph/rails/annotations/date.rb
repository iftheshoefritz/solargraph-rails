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

  # @return [-1, 0, 1, nil]
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
  # @return [String]
  def readable_inspect; end

  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

# annotation is wrong in RBS, so use an override instead of a class

# @!override DateTime#as_json
#   @return [String]
