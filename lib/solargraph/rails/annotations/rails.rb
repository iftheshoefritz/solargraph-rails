class Rails::Application
  # @param subclass [Class]
  # @return [void]
  # rubocop:disable Lint/MissingSuper
  def self.inherited(subclass); end
  # rubocop:enable Lint/MissingSuper
end
