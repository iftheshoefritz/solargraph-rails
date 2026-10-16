module ActionController
  class Base < Metal
    #
    # NOTE: keep this list synced with new items from MODULES in action_controller/base.rb
    #
    # @todo pull this as literal array dynamically from
    #  ActionController::Base::MODULES and walk through it (and other
    #  cases of same pattern) to help future-proof things
    #
    include RequestForgeryProtection
    extend RequestForgeryProtection::ClassMethods
    include PermissionsPolicy
    extend PermissionsPolicy::ClassMethods
    include Logging
    extend Logging::ClassMethods

    #
    # I don't see the thinsg below in action_controller/base.rb, at least in Rails
    # 7.0.  Maybe they need to be moved to be under a different class?
    #
    extend ActiveSupport::Callbacks::ClassMethods
    include AbstractController::Caching::ClassMethods

    # @return [ActionDispatch::Response]
    def response; end
    # @return [ActionDispatch::Request]
    def request; end
    # @return [ActionDispatch::Request::Session]
    def session; end
    # @return [ActionDispatch::Flash::FlashHash]
    def flash; end
  end
end

# @!override ActionController::Rescue#show_detailed_exceptions?
#   @return [Boolean]

class AbstractController::Base
  include Rails::Application::Configuration
  extend Rails::Application::Configuration

  # @param method_name [Symbol]
  # @return [void]
  # rubocop:disable Lint/MissingSuper
  def self.method_added(method_name); end
  # rubocop:enable Lint/MissingSuper
end

class ActionController::Metal
  # @return [ActionController::Parameters]
  def params; end
end

class ActionController::Cookies
  # @return [ActionDispatch::Cookies::CookieJar]
  def cookies; end
end

class ActionController::StrongParameters
  # @return [ActionController::Parameters]
  def params; end
end
