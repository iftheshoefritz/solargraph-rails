class ActionController::Base
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
  include AbstractController::AssetPaths
  include Helpers
  include UrlFor
  include Redirecting
  include ActionView::Layouts
  include Rendering
  include Renderers::All
  include ConditionalGet
  include EtagWithTemplateDigest
  include EtagWithFlash
  include Caching
  include MimeResponds
  include ImplicitRender
  include StrongParameters
  include ParameterEncoding
  include Cookies
  include Flash
  include FormBuilder
  include RequestForgeryProtection
  extend RequestForgeryProtection::ClassMethods
  include ContentSecurityPolicy
  include PermissionsPolicy
  extend PermissionsPolicy::ClassMethods
  include Streaming
  include DataStreaming
  include HttpAuthentication::Basic::ControllerMethods
  extend HttpAuthentication::Basic::ControllerMethods::ClassMethods
  include HttpAuthentication::Digest::ControllerMethods
  include HttpAuthentication::Token::ControllerMethods
  include DefaultHeaders
  include Logging
  include AbstractController::Callbacks
  extend AbstractController::Callbacks::ClassMethods
  include Rescue
  include Instrumentation
  include ParamsWrapper

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
