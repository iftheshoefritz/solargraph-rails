class ActiveRecord::Persistence::ClassMethods
  # @return [self]
  def create(attributes = nil, &block); end
end

class ActiveRecord::Base
  # @return [self, Array<self>]
  def self.create!(attributes = nil, &block); end
end

# @!override ActiveRecord::Calculations#pluck
#   @overload pluck(one)
#     @return [Array]
#   @overload pluck(one, two, *more)
#     @return [Array<Array>]
