class Rails::Application
  # Delete once https://github.com/ruby/gem_rbs_collection/pull/1122 lands.
  # @param subclass [Class]
  # @return [void]
  # rubocop:disable Lint/MissingSuper
  def self.inherited(subclass); end
  # rubocop:enable Lint/MissingSuper
end
