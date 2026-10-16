class ActiveRecord::Persistence::ClassMethods
  # @return [self]
  def create(attributes = nil, &block); end
end

class ActiveRecord::Base
  # @return [self, Array<self>]
  def self.create!(attributes = nil, &block); end
end
