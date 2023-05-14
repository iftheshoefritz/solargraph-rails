require 'time'

# @!override Time#eql_with_coercion
#   @return [Boolean]
# @!override Time#compare_with_coercion
#   @return [-1, 0, 1, nil]
# @!override Time#compare_without_coercion
#   @return [-1, 0, 1, nil]
# @!override Time#<=>
#   @return [-1, 0, 1, nil]
# @!override Time.at
#   @return [Time]
# @!override Time#to_time
#   @return [Time]
# @!override Time#+
#   @return [Time]
