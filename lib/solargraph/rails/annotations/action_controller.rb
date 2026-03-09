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
    extend AbstractController::Rendering::ClassMethods
    include AbstractController::Translation
    extend AbstractController::Translation::ClassMethods
    include AbstractController::AssetPaths
    extend AbstractController::AssetPaths::ClassMethods
    include Helpers
    extend Helpers::ClassMethods
    include UrlFor
    extend UrlFor::ClassMethods
    include Redirecting
    extend Redirecting::ClassMethods
    include ActionView::Layouts
    extend ActionView::Layouts::ClassMethods
    include Rendering
    extend Rendering::ClassMethods
    include Renderers::All
    extend Renderers::All::ClassMethods
    include ConditionalGet
    extend ConditionalGet::ClassMethods
    include EtagWithTemplateDigest
    extend EtagWithTemplateDigest::ClassMethods
    include EtagWithFlash
    extend EtagWithFlash::ClassMethods
    include Caching
    extend Caching::ClassMethods
    include MimeResponds
    extend MimeResponds::ClassMethods
    include ImplicitRender
    extend ImplicitRender::ClassMethods
    include StrongParameters
    extend StrongParameters::ClassMethods
    include ParameterEncoding
    extend ParameterEncoding::ClassMethods
    include Cookies
    extend Cookies::ClassMethods
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
    extend Streaming::ClassMethods
    include DataStreaming
    extend DataStreaming::ClassMethods
    include HttpAuthentication::Basic::ControllerMethods
    extend HttpAuthentication::Basic::ControllerMethods::ClassMethods
    include HttpAuthentication::Digest::ControllerMethods
    extend HttpAuthentication::Digest::ControllerMethods::ClassMethods
    include HttpAuthentication::Token::ControllerMethods
    extend HttpAuthentication::Token::ControllerMethods::ClassMethods
    include DefaultHeaders
    extend DefaultHeaders::ClassMethods
    include Logging
    extend Logging::ClassMethods
    include AbstractController::Callbacks
    extend AbstractController::Callbacks::ClassMethods
    include Rescue
    extend Rescue::ClassMethods
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

class AbstractController::Base
  include Rails::Application::Configuration
  extend Rails::Application::Configuration
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
