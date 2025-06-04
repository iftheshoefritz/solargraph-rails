class ActionController::Base
  include ActionController::MimeResponds
  include ActionController::Redirecting
  include ActionController::Cookies
  include AbstractController::Rendering
  extend AbstractController::Rendering::ClassMethods
  include ActionView::Layouts
  include HttpAuthentication::Basic::ControllerMethods
  extend HttpAuthentication::Basic::ControllerMethods::ClassMethods
  include HttpAuthentication::Digest::ControllerMethods
  include HttpAuthentication::Token::ControllerMethods
  extend ActiveSupport::Callbacks::ClassMethods
  extend ActiveSupport::Rescuable::ClassMethods
  include ActiveSupport::Rescuable
  extend AbstractController::Callbacks::ClassMethods
  extend ActionController::RequestForgeryProtection::ClassMethods
  extend ActionController::HttpAuthentication::Basic::ControllerMethods::ClassMethods
  include ActionController::HttpAuthentication::Basic::ControllerMethods
  include ActionController::HttpAuthentication::Digest::ControllerMethods

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
