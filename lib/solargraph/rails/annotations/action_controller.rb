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

    # Defined at runtime by class_attribute, config_accessor and mattr_accessor.
    # Only those present since Rails 7.0: these declarations are not version-gated.
    # @return [Boolean]
    def self.allow_forgery_protection; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.allow_forgery_protection=(value); end
    # @return [Boolean]
    def allow_forgery_protection; end
    # @param value [Boolean]
    # @return [Boolean]
    def allow_forgery_protection=(value); end
    # @return [Boolean]
    def self.log_warning_on_csrf_failure; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.log_warning_on_csrf_failure=(value); end
    # @return [Boolean]
    def log_warning_on_csrf_failure; end
    # @param value [Boolean]
    # @return [Boolean]
    def log_warning_on_csrf_failure=(value); end
    # @return [Boolean]
    def self.forgery_protection_origin_check; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.forgery_protection_origin_check=(value); end
    # @return [Boolean]
    def forgery_protection_origin_check; end
    # @param value [Boolean]
    # @return [Boolean]
    def forgery_protection_origin_check=(value); end
    # @return [Boolean]
    def self.per_form_csrf_tokens; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.per_form_csrf_tokens=(value); end
    # @return [Boolean]
    def per_form_csrf_tokens; end
    # @param value [Boolean]
    # @return [Boolean]
    def per_form_csrf_tokens=(value); end
    # @return [Boolean]
    def self.perform_caching; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.perform_caching=(value); end
    # @return [Boolean]
    def perform_caching; end
    # @param value [Boolean]
    # @return [Boolean]
    def perform_caching=(value); end
    # @return [Boolean]
    def self.enable_fragment_cache_logging; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.enable_fragment_cache_logging=(value); end
    # @return [Boolean]
    def enable_fragment_cache_logging; end
    # @param value [Boolean]
    # @return [Boolean]
    def enable_fragment_cache_logging=(value); end
    # @return [Boolean]
    def self.etag_with_template_digest; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.etag_with_template_digest=(value); end
    # @return [Boolean]
    def self.etag_with_template_digest?; end
    # @return [Boolean]
    def etag_with_template_digest; end
    # @param value [Boolean]
    # @return [Boolean]
    def etag_with_template_digest=(value); end
    # @return [Boolean]
    def etag_with_template_digest?; end
    # @return [Boolean]
    def self.include_all_helpers; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.include_all_helpers=(value); end
    # @return [Boolean]
    def self.include_all_helpers?; end
    # @return [Boolean]
    def include_all_helpers; end
    # @param value [Boolean]
    # @return [Boolean]
    def include_all_helpers=(value); end
    # @return [Boolean]
    def include_all_helpers?; end
    # @return [Boolean]
    def self.raise_on_open_redirects; end
    # @param value [Boolean]
    # @return [Boolean]
    def self.raise_on_open_redirects=(value); end
    # @return [Boolean]
    def raise_on_open_redirects; end
    # @param value [Boolean]
    # @return [Boolean]
    def raise_on_open_redirects=(value); end
    # @return [String]
    def self.default_static_extension; end
    # @param value [String]
    # @return [String]
    def self.default_static_extension=(value); end
    # @return [String]
    def default_static_extension; end
    # @param value [String]
    # @return [String]
    def default_static_extension=(value); end
    # @return [Symbol]
    def self.request_forgery_protection_token; end
    # @param value [Symbol]
    # @return [Symbol]
    def self.request_forgery_protection_token=(value); end
    # @return [Symbol]
    def request_forgery_protection_token; end
    # @param value [Symbol]
    # @return [Symbol]
    def request_forgery_protection_token=(value); end
    # @return [Class, nil]
    def self.forgery_protection_strategy; end
    # @param value [Class, nil]
    # @return [Class, nil]
    def self.forgery_protection_strategy=(value); end
    # @return [Class, nil]
    def forgery_protection_strategy; end
    # @param value [Class, nil]
    # @return [Class, nil]
    def forgery_protection_strategy=(value); end
    # @return [String, Symbol, nil]
    def self.default_asset_host_protocol; end
    # @param value [String, Symbol, nil]
    # @return [String, Symbol, nil]
    def self.default_asset_host_protocol=(value); end
    # @return [Hash]
    def self.default_url_options; end
    # @param value [Hash]
    # @return [Hash]
    def self.default_url_options=(value); end
    # @return [Boolean]
    def self.default_url_options?; end
    # @return [Hash]
    def default_url_options; end
    # @param value [Hash]
    # @return [Hash]
    def default_url_options=(value); end
    # @return [Boolean]
    def default_url_options?; end
    # @return [Array]
    def self.etaggers; end
    # @param value [Array]
    # @return [Array]
    def self.etaggers=(value); end
    # @return [Boolean]
    def self.etaggers?; end
    # @return [Array]
    def etaggers; end
    # @param value [Array]
    # @return [Array]
    def etaggers=(value); end
    # @return [Boolean]
    def etaggers?; end
    # @return [Array]
    def self.fragment_cache_keys; end
    # @param value [Array]
    # @return [Array]
    def self.fragment_cache_keys=(value); end
    # @return [Boolean]
    def self.fragment_cache_keys?; end
    # @return [Array]
    def fragment_cache_keys; end
    # @param value [Array]
    # @return [Array]
    def fragment_cache_keys=(value); end
    # @return [Boolean]
    def fragment_cache_keys?; end
    # @return [Boolean]
    def self.helpers_path?; end
    # @return [Array]
    def helpers_path; end
    # @param value [Array]
    # @return [Array]
    def helpers_path=(value); end
    # @return [Boolean]
    def helpers_path?; end
    # @return [Array]
    def self.rescue_handlers; end
    # @param value [Array]
    # @return [Array]
    def self.rescue_handlers=(value); end
    # @return [Boolean]
    def self.rescue_handlers?; end
    # @return [Array]
    def rescue_handlers; end
    # @param value [Array]
    # @return [Array]
    def rescue_handlers=(value); end
    # @return [Boolean]
    def rescue_handlers?; end
    # @return [ActionController::MiddlewareStack]
    def middleware_stack; end
    # @param value [ActionController::MiddlewareStack]
    # @return [ActionController::MiddlewareStack]
    def middleware_stack=(value); end
    # @return [Boolean]
    def middleware_stack?; end

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
