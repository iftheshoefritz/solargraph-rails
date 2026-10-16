# gem_rbs_collection types these from activerecord 7.2 on; older Rails
# resolves activerecord RBS that returns untyped or lacks the Array
# overload.
class ActiveRecord::Persistence::ClassMethods
  # @return [self]
  def create(attributes = nil, &block); end
end

class ActiveRecord::Base
  # @return [self, Array<self>]
  def self.create!(attributes = nil, &block); end
end
