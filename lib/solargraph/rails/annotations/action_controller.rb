module ActionController
  class Base < Metal
    #
    # NOTE: keep this list synced with new items from MODULES in action_controller/base.rb
    #
    # @todo pull this as literal array dynamically from
    #  ActionController::Base::MODULES and walk through it (and other
    #  cases of same pattern) to help future-proof things
    #
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

    # Wrong in the gem RBS, which types this by AbstractController::Base's
    # body as true, but ActionMailer::Base returns false.
    # Delete once https://github.com/apiology/gem_rbs_collection/pull/17 merges.
    # @return [Boolean]
    def self.supports_path?; end
  end
end

# @!override ActionController::Rescue#show_detailed_exceptions?
#   @return [Boolean]

class AbstractController::Base
  # Move to a solargraph_before_<release> directory once https://github.com/castwide/solargraph/pull/1403 ships in a release.
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
