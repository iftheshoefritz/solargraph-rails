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
end
