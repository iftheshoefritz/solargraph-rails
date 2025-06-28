class ActiveRecord::ConnectionAdapters::SchemaStatements
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  # @return [void]
  def create_table(table_name, id: nil, primary_key: nil, force: false, **options); end
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  # @param column_options [Hash]
  # @return [void]
  def create_join_table(table_1, table_2, column_options: {}, **options); end
  # @yieldparam [ActiveRecord::ConnectionAdapters::Table]
  # @return [void]
  def change_table(table_name, **options); end
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
  extend Enumerable
  extend ActiveRecord::QueryMethods
  extend ActiveRecord::FinderMethods
  extend ActiveRecord::Calculations
  extend ActiveRecord::Batches
  extend ActiveRecord::Associations::ClassMethods
  extend ActiveRecord::Inheritance::ClassMethods
  extend ActiveRecord::ModelSchema::ClassMethods
  extend ActiveRecord::Transactions::ClassMethods
  extend ActiveRecord::Scoping::Named::ClassMethods
  extend ActiveRecord::RelationMethods
  include ActiveRecord::Persistence
  extend ActiveModel::AttributeRegistration::ClassMethods
  # note: this supplies set_callback() - after Rails 7.1, this is no
  #  longer used and is replaced entirely by ActiveRecord::Callbacks
  #  below
  include ActiveRecord::Callbacks
  extend ActiveRecord::Callbacks::ClassMethods
  extend Translation

  def self.set_callback
  end
end

module ActiveRecord::Validations
  # @return [Boolean]
  def validate; end
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
# @!override ActiveRecord::ConnectionAdapters::SchemaStatements#create_table
#   @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
