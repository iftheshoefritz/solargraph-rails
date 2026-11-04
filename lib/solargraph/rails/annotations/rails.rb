class Rails::Application
  # Delete once https://github.com/ruby/gem_rbs_collection/pull/1122 merges.
  # @param subclass [Class]
  # @return [void]
  # rubocop:disable Lint/MissingSuper
  def self.inherited(subclass); end
  # rubocop:enable Lint/MissingSuper
end

# Initializer#run yields the application being initialized.
# @!override Rails::Initializable::ClassMethods#initializer
#   @yieldparam app [Rails::Application]
