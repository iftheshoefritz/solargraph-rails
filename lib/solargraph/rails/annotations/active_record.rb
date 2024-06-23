class ActiveRecord::ConnectionAdapters::SchemaStatements
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  def create_table; end
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  def create_join_table; end
  # @yieldparam [ActiveRecord::ConnectionAdapters::Table]
  def change_table; end
end

# this module doesn't really exist, it's here to avoid repeating these mixins
module ActiveRecord::RelationMethods
  include Enumerable
  include ActiveRecord::QueryMethods
  include ActiveRecord::FinderMethods
  include ActiveRecord::Calculations
  include ActiveRecord::Batches
end

class ActiveRecord::Relation
  include ActiveRecord::RelationMethods
end

class ActiveRecord::Base
  extend ActiveRecord::Associations::ClassMethods
  extend ActiveRecord::Inheritance::ClassMethods
  extend ActiveRecord::ModelSchema::ClassMethods
  extend ActiveRecord::Transactions::ClassMethods
  extend ActiveRecord::Scoping::Named::ClassMethods
  extend ActiveRecord::RelationMethods
  include ActiveRecord::Persistence
end

# @!override ActiveRecord::Batches#find_each
#   @yieldparam_single_parameter

# @!override ActiveRecord::Calculations#count
#   @return [Integer, Hash]
# @!override ActiveRecord::Calculations#pluck
#   @overload pluck(one)
#     @return [Array]
#   @overload pluck(one, two, *more)
#     @return [Array<Array>]

# @!override ActiveRecord::QueryMethods::WhereChain#not
#   @return_single_parameter
# @!override ActiveRecord::QueryMethods::WhereChain#missing
#   @return_single_parameter
# @!override ActiveRecord::QueryMethods::WhereChain#associated
#   @return_single_parameter
