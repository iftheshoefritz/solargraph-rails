class ActiveRecord::Base
  extend ActiveRecord::Associations::ClassMethods
  extend ActiveRecord::Inheritance::ClassMethods
  include ActiveRecord::ModelSchema
  extend ActiveRecord::ModelSchema::ClassMethods
  include ActiveRecord::Transactions
  extend ActiveRecord::Transactions::ClassMethods
  include ActiveRecord::Scoping::Named
  extend ActiveRecord::Scoping::Named::ClassMethods
  include ActiveRecord::Persistence
  extend ActiveRecord::Persistence::ClassMethods
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

  include ActiveRecord::Timestamp
  extend ActiveRecord::Timestamp::ClassMethods

  extend ActiveRecord::AttributeMethods

  include ActiveModel::Validations
  extend ActiveModel::Validations::ClassMethods

  extend ActiveRecord::Core::ClassMethods

  class << self
    # included in ActiveRecordExtensions
    # @return [Hash{String => ActiveStorage::Reflection::HasOneAttachedReflection, ActiveStorage::Reflection::HasManyAttachedReflection}]
    attr_accessor :attachment_reflections
  end

  extend ::ActiveStorage::Reflection::ActiveRecordExtensions::ClassMethods

  def self.set_callback; end

  # @param id [Integer, String]
  # @param counters [Array<Symbol, String>] association or counter names
  # @param touch [Boolean, Symbol, Array<Symbol>, nil]
  # @return [Boolean]
  def self.reset_counters(id, *counters, touch: nil); end
end

# @!override ActiveRecord::Core#blank?
#   @return [Boolean]
# @!override ActiveRecord::Core#present?
#   @return [Boolean]
# @!override ActiveModel::Validations#validate!
#   @return [Boolean]

# @!override ActiveRecord::QueryMethods::WhereChain#not
#   @return_single_parameter
# @!override ActiveRecord::QueryMethods::WhereChain#missing
#   @return_single_parameter
# @!override ActiveRecord::QueryMethods::WhereChain#associated
#   @return_single_parameter
