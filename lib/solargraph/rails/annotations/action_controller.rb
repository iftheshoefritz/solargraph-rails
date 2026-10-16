module ActionController
  class Base < Metal
    #
    # NOTE: keep this list synced with new items from MODULES in action_controller/base.rb
    #
    # @todo pull this as literal array dynamically from
    #  ActionController::Base::MODULES and walk through it (and other
    #  cases of same pattern) to help future-proof things
    #
    include AbstractController::Rendering
    include AbstractController::Translation
    include AbstractController::AssetPaths
    include Helpers
    extend Helpers::ClassMethods
    include UrlFor
    include Redirecting
    include ActionView::Layouts
    extend ActionView::Layouts::ClassMethods
    include Rendering
    extend Rendering::ClassMethods
    include Renderers::All
    include ConditionalGet
    extend ConditionalGet::ClassMethods
    include EtagWithTemplateDigest
    include EtagWithFlash
    include Caching
    extend Caching::ClassMethods
    include MimeResponds
    include ImplicitRender
    include StrongParameters
    include ParameterEncoding
    extend ParameterEncoding::ClassMethods
    include Cookies
    include Flash
    extend Flash::ClassMethods
    include FormBuilder
    extend FormBuilder::ClassMethods
    include RequestForgeryProtection
    extend RequestForgeryProtection::ClassMethods
    include ContentSecurityPolicy
    extend ContentSecurityPolicy::ClassMethods
    include PermissionsPolicy
    extend PermissionsPolicy::ClassMethods
    include Streaming
    include DataStreaming
    include HttpAuthentication::Basic::ControllerMethods
    extend HttpAuthentication::Basic::ControllerMethods::ClassMethods
    include HttpAuthentication::Digest::ControllerMethods
    include HttpAuthentication::Token::ControllerMethods
    include DefaultHeaders
    extend DefaultHeaders::ClassMethods
    include Logging
    extend Logging::ClassMethods
    include AbstractController::Callbacks
    extend AbstractController::Callbacks::ClassMethods
    include Rescue
    include Instrumentation
    extend Instrumentation::ClassMethods
    include ParamsWrapper
    extend ParamsWrapper::ClassMethods

    #
    # I don't see the thinsg below in action_controller/base.rb, at least in Rails
    # 7.0.  Maybe they need to be moved to be under a different class?
    #
    extend ActiveSupport::Callbacks::ClassMethods
    extend ActiveSupport::Rescuable::ClassMethods
    include ActiveSupport::Rescuable
    include AbstractController::Helpers
    extend AbstractController::Helpers::ClassMethods
    include AbstractController::Caching
    include AbstractController::Caching::ClassMethods

    # @return [ActionDispatch::Response]
    def response; end
    # @return [ActionDispatch::Request]
    def request; end
    # @return [ActionDispatch::Request::Session]
    def session; end
    # @return [ActionDispatch::Flash::FlashHash]
    def flash; end

    # @return [Boolean]
    def self.supports_path?; end
  end
end

# @!override ActionController::Head#head
#   @return [Boolean]
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
