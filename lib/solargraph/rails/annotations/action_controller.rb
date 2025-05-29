class ActionController::Base
  include ActionController::MimeResponds
  include ActionController::Redirecting
  include ActionController::Cookies
  include AbstractController::Rendering
  extend ActiveSupport::Callbacks::ClassMethods
  extend ActiveSupport::Rescuable::ClassMethods
  extend AbstractController::Callbacks::ClassMethods
  extend ActionController::RequestForgeryProtection::ClassMethods

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
