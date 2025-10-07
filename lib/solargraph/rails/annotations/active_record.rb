require 'active_record'

class ActiveRecord::ConnectionAdapters::SchemaStatements
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  # @return [void]
  def create_table(table_name, id: nil, primary_key: nil, force: false, **options); end
  # @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
  # @param table_1 [String, Symbol]
  # @param table_2 [String, Symbol]
  # @param column_options [Hash]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def create_join_table(table_1, table_2, column_options: {}, **options); end
  # @yieldparam [ActiveRecord::ConnectionAdapters::Table]
  # @return [void]
  def change_table(table_name, **options); end
end

class ActiveRecord::ConnectionAdapters::ColumnMethods
  # included do
  #   define_column_methods :bigint, :binary, :boolean, :date, :datetime, :decimal,
  #     :float, :integer, :json, :string, :text, :time, :timestamp, :virtual
  #   alias :blob :binary
  #   alias :numeric :decimal
  # end

  # def define_column_methods(*column_types) # :nodoc:
  #   column_types.each do |column_type|
  #     module_eval <<-RUBY, __FILE__, __LINE__ + 1
  #       def #{column_type}(*names, **options)
  #         raise ArgumentError, "Missing column name(s) for #{column_type}" if names.empty?
  #         names.each { |name| column(name, :#{column_type}, **options) }
  #       end
  #     RUBY
  #   end

  # decimal
  #
  # @param names [Array<Symbol, String>]
  # @param precision [Integer, nil]
  # @param scale [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def decimal(*names, precision: nil, scale: nil, **options); end
  # bigint
  #
  # @param names [Array<Symbol, String>]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def bigint(*names, **options); end
  # virtual
  #
  # @param names [Array<Symbol, String>]
  # @param type [Symbol, String]
  # @param as [String]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def virtual(*names, type, as:, **options); end
  # json
  #
  # @param names [Array<Symbol, String>]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def json(*names, **options); end
  # jsonb
  #
  # @param names [Array<Symbol, String>]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def jsonb(*names, **options); end
  # boolean
  #
  # @param names [Array<Symbol, String>]
  # @param options [Hash{Symbol => undefined}]
  # @param names [Array<Symbol, String>]
  # @return [void]
  def boolean(*names, **options); end
  # string
  #
  # @param names [Array<Symbol, String>]
  # @param limit [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def string(*names, limit: nil, **options); end
  # text
  #
  # @param names [Array<Symbol, String>]
  # @param limit [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def text(*names, limit: nil, **options); end
  # integer
  #
  # @param names [Array<Symbol, String>]
  # @param limit [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def integer(*names, limit: nil, **options); end
  # float
  #
  # @param names [Array<Symbol, String>]
  # @param limit [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def float(*names, limit: nil, **options); end
  # binary
  #
  # @param names [Array<Symbol, String>]
  # @param limit [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def binary(*names, limit: nil, **options); end
  # date
  #
  # @param names [Array<Symbol, String>]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def date(*names, **options); end
  # datetime
  #
  # @param names [Array<Symbol, String>]
  # @param precision [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def datetime(*names, precision: nil, **options); end
  # time
  #
  # @param names [Array<Symbol, String>]
  # @param precision [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def time(*names, precision: nil, **options); end
  # timestamp
  #
  # @param names [Array<Symbol, String>]
  # @param precision [Integer, nil]
  # @param options [Hash{Symbol => undefined}]
  # @return [void]
  def timestamp(*names, precision: nil, **options); end
end

module ActiveRecord::Core
  # @param methods [Symbol]
  # @return [ActiveSupport::HashWithIndifferentAccess<Symbol>]
  def slice(*methods); end
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

module ActiveRecord
  class Schema
    # @param version [Numeric]
    #
    # @return [Class<ActiveRecord::Schema>]
    def self.[](version); end

    # @yieldreceiver [ActiveRecord::ConnectionAdapters::SchemaStatements]
    def self.define(info = {}, &block); end
  end
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
  extend ActiveRecord::Translation

  # copied from .gem_rbs_collection/activestorage/7.0/lib/engine.rbs
  # which for some reason does not get included
  include ::ActiveStorage::Attached::Model
  extend ::ActiveStorage::Attached::Model::ClassMethods
  include ::ActiveStorage::Reflection::ActiveRecordExtensions

  class << self
    # included in ActiveRecordExtensions
    # @return [Hash{String => ActiveStorage::Reflection::HasOneAttachedReflection, ActiveStorage::Reflection::HasManyAttachedReflection}]
    attr_accessor :attachment_reflections
  end

  extend ::ActiveStorage::Reflection::ActiveRecordExtensions::ClassMethods

  def self.set_callback; end

  # @return [:activerecord]
  def self.i18n_scope; end

  # @return [self]
  def reload(); end
end

module ActiveRecord::Validations
  # @return [Boolean]
  def validate(); end
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
