class Rails
  # @return [Rails::Application]
  def self.application; end
end

class Rails::Engine
  # @return [ActionDispatch::Routing::RouteSet]
  def routes; end
end

class Rails::Application
  # @return [ActionDispatch::Routing::RouteSet]
  def routes; end
  # @return [Rails::Application::Configuration]
  def config; end
  # @return [Rails::Application::Configuration]
  def self.config; end
  # @yieldreceiver [self]
  def configure; end

  # @param subclass [Class]
  # @return [void]
  # rubocop:disable Lint/MissingSuper
  def self.inherited(subclass); end
  # rubocop:enable Lint/MissingSuper
end
