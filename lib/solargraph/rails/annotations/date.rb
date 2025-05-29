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
end

class DateTime
  # @return [String]
  def readable_inspect; end
end
