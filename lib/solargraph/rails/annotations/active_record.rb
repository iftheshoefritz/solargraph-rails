require 'active_record'
require 'turbo'

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

  # Wrong: Rails returns a record, or an Array of records for an Array
  # argument, not the relation. Delete once
  # https://github.com/apiology/gem_rbs_collection/pull/5 lands.
  # @return [self]
  def build(attributes = nil, &block); end
end

class ActiveRecord::Persistence::ClassMethods
  # @return [self]
  def build(attributes = nil, &block); end
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
  # Move to a solargraph_before_<release> directory once
  # https://github.com/iftheshoefritz/solargraph-rails/pull/227,
  # https://github.com/castwide/solargraph/pull/1378 and
  # https://github.com/castwide/solargraph/pull/1406 ship, plus
  # https://github.com/castwide/solargraph/pull/1344 and
  # https://github.com/castwide/solargraph/pull/1415 for the count and pluck types.
  extend Enumerable
  extend ActiveRecord::QueryMethods
  extend ActiveRecord::FinderMethods
  extend ActiveRecord::Calculations
  extend ActiveRecord::Batches
  extend ActiveRecord::Associations::CollectionProxy
  extend ActiveRecord::RelationMethods
  extend ActiveRecord::Relation

  include ActiveRecord::SignedId
  extend ActiveRecord::SignedId::ClassMethods

  include ::Turbo::Broadcastable
  extend ::Turbo::Broadcastable::ClassMethods

  # Move to a solargraph_before_<release> directory once https://github.com/castwide/solargraph/pull/1378 ships in a release.
  extend ActiveRecord::Core

  # Move to a solargraph_before_<release> directory once https://github.com/apiology/solargraph/pull/199 ships in a release.
  # An Array of attribute hashes creates and returns an Array of records.
  # @return [self, Array<self>]
  def self.create(attributes = nil, &block); end

  # @return [self]
  def reload; end

  # @param other [Object]
  # @return [Integer, nil]
  def <=>(other); end
end

module ActiveRecord::Validations
  # @return [Boolean]
  def validate; end
end

# @!override ActiveRecord::Calculations#count
#   @return [Integer, Hash]

# Delete the pluck override once
# https://github.com/apiology/gem_rbs_collection/pull/13 lands.
# @!override ActiveRecord::Calculations#pluck
#   @overload pluck(one)
#     @return [Array]
#   @overload pluck(one, two, *more)
#     @return [Array<Array>]

# @!override ActiveRecord::ConnectionAdapters::SchemaStatements#create_table
#   @yieldparam [ActiveRecord::ConnectionAdapters::TableDefinition]
