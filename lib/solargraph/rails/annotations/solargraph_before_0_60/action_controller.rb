module ActionController
  class Base < Metal
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
    # Rails has no Caching::ClassMethods, but Solargraph 0.48-0.52
    # resolve this to AbstractController::Caching::ClassMethods.
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
    include ContentSecurityPolicy
    extend ContentSecurityPolicy::ClassMethods
    include Streaming
    include DataStreaming
    include HttpAuthentication::Basic::ControllerMethods
    extend HttpAuthentication::Basic::ControllerMethods::ClassMethods
    include HttpAuthentication::Digest::ControllerMethods
    include HttpAuthentication::Token::ControllerMethods
    include DefaultHeaders
    extend DefaultHeaders::ClassMethods
    include AbstractController::Callbacks
    extend AbstractController::Callbacks::ClassMethods
    include Rescue
    include Instrumentation
    extend Instrumentation::ClassMethods
    include ParamsWrapper
    extend ParamsWrapper::ClassMethods

    extend ActiveSupport::Rescuable::ClassMethods
    include ActiveSupport::Rescuable
    include AbstractController::Helpers
    extend AbstractController::Helpers::ClassMethods
    include AbstractController::Caching

    # @return [Boolean]
    def self.supports_path?; end
  end
end

# @!override ActionController::Head#head
#   @return [Boolean]
