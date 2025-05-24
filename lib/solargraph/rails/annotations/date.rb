require 'date'
require 'active_support/core_ext'

class Date
  # @param form [Symbol]
  # @return [Time]
  def to_time(form = :local); end
end
# @!override Date#-
#   @return [Rational, self]
# @!override Date#+
#   @return [self]
# @!override Date#readable_inspect
#   @return [String]
# @!override DateTime#readable_inspect
#   @return [String]
# @!override Date#compare_with_coercion
#   @return [-1, 0, 1, nil]
# @!override Date#compare_without_coercion
#   @return [-1, 0, 1, nil]
# @!override Date#<=>
#   @return [-1, 0, 1, nil]
# @!override Date#to_time
#   @return [::Time]
