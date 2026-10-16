# gem_rbs_collection types these from actionpack 7.2 on; older Rails
# resolves actionpack/6.0 RBS, which lacks them.
module ActionController
  module HttpAuthentication
    module Basic
      module ControllerMethods
        module ClassMethods
          # @param name [String]
          # @param password [String]
          # @param realm [String, nil]
          # @param options [Hash]
          # @return [void]
          def http_basic_authenticate_with(name:, password:, realm: nil, **options); end
        end

        # @param name [String]
        # @param password [String]
        # @param realm [String, nil]
        # @param message [String, nil]
        # @return [true, String]
        def http_basic_authenticate_or_request_with(name:, password:, realm: nil, message: nil); end

        # @generic T
        # @param realm [String, nil]
        # @param message [String, nil]
        # @yieldparam name [String, nil]
        # @yieldparam password [String, nil]
        # @yieldreturn [generic<T>]
        # @return [generic<T>, String]
        def authenticate_or_request_with_http_basic(realm = nil, message = nil); end

        # @generic T
        # @yieldparam name [String, nil]
        # @yieldparam password [String, nil]
        # @yieldreturn [generic<T>]
        # @return [generic<T>, nil]
        def authenticate_with_http_basic; end

        # @param realm [String]
        # @param message [String, nil]
        # @return [String]
        def request_http_basic_authentication(realm = 'Application', message = nil); end
      end
    end

    module Digest
      module ControllerMethods
        # @param realm [String]
        # @param message [String, nil]
        # @yieldparam username [String, nil]
        # @yieldreturn [String, nil]
        # @return [true, String]
        def authenticate_or_request_with_http_digest(realm = 'Application', message = nil); end

        # @param realm [String]
        # @yieldparam username [String, nil]
        # @yieldreturn [String, nil]
        # @return [Boolean, nil]
        def authenticate_with_http_digest(realm = 'Application'); end

        # @param realm [String]
        # @param message [String, nil]
        # @return [String]
        def request_http_digest_authentication(realm = 'Application', message = nil); end
      end
    end

    module Token
      module ControllerMethods
        # @generic T
        # @param realm [String]
        # @param message [String, nil]
        # @yieldparam token [String]
        # @yieldparam options [ActiveSupport::HashWithIndifferentAccess]
        # @yieldreturn [generic<T>]
        # @return [generic<T>, String]
        def authenticate_or_request_with_http_token(realm = 'Application', message = nil); end

        # @generic T
        # @yieldparam token [String]
        # @yieldparam options [ActiveSupport::HashWithIndifferentAccess]
        # @yieldreturn [generic<T>]
        # @return [generic<T>, nil]
        def authenticate_with_http_token; end

        # @param realm [String]
        # @param message [String, nil]
        # @return [String]
        def request_http_token_authentication(realm = 'Application', message = nil); end
      end
    end
  end
end

# actionpack/6.0 RBS types this as void, which would otherwise combine
# with the String above.
#
# @!override ActionController::HttpAuthentication::Token::ControllerMethods#request_http_token_authentication
#   @return [String]
