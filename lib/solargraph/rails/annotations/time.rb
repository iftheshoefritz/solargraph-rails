require 'time'

class Time
  # @return [Boolean]
  def eql_with_coercion(other); end

  # @return [-1, 0, 1, nil]
  def compare_with_coercion(other); end

  # @return [-1, 0, 1, nil]
  def compare_without_coercion(other); end

  # @return [-1, 0, 1, nil]
  def <=>(other); end

  # @return [Time]
  def +(other); end

  # @param seconds [Integer, Float]
  # @param microseconds [Integer]
  # @param utc [Boolean]
  # @return [Time]
  def self.at(seconds, microseconds = 0, utc = false); end

  # @return [Time]
  def to_time; end

  # @param format [Symbol]
  # @return [String]
  def to_formatted_s(format = :some_default); end
end

# @!override Time#+
#   @return [Time]
