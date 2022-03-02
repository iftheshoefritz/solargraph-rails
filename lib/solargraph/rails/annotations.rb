# The following comments fill some of the gaps in Solargraph's understanding of
# Rails apps. Since they're all in YARD, they get mapped in Solargraph but
# ignored at runtime.
#
# You can put this file anywhere in the project, as long as it gets included in
# the workspace maps. It's recommended that you keep it in a standalone file
# instead of pasting it into an existing one.
#
# @!parse
#   class ActionController::Base
#     include ActionController::MimeResponds
#     include ActionController::Redirecting
#     include ActionController::Cookies
#     include AbstractController::Rendering
#     extend ActiveSupport::Callbacks::ClassMethods
#     extend ActiveSupport::Rescuable::ClassMethods
#     extend AbstractController::Callbacks::ClassMethods
#     extend ActionController::RequestForgeryProtection::ClassMethods
#   end
#   class ActionDispatch::Routing::Mapper
#     include ActionDispatch::Routing::Mapper::Base
#     include ActionDispatch::Routing::Mapper::HttpHelpers
#     include ActionDispatch::Routing::Mapper::Redirection
#     include ActionDispatch::Routing::Mapper::Scoping
#     include ActionDispatch::Routing::Mapper::Concerns
#     include ActionDispatch::Routing::Mapper::Resources
#     include ActionDispatch::Routing::Mapper::CustomUrls
#   end
#   class Rails
#     # @return [Rails::Application]
#     def self.application; end
#   end
#   class Rails::Application
#     # @return [ActionDispatch::Routing::RouteSet]
#     def routes; end
#   end
#   class ActionDispatch::Routing::RouteSet
#     # @yieldself [ActionDispatch::Routing::Mapper]
#     def draw; end
#   end
#   class ActiveRecord::Base
#     extend ActiveRecord::QueryMethods
#     extend ActiveRecord::FinderMethods
#     extend ActiveRecord::Associations::ClassMethods
#     extend ActiveRecord::Inheritance::ClassMethods
#     extend ActiveRecord::ModelSchema::ClassMethods
#     extend ActiveRecord::Transactions::ClassMethods
#     extend ActiveRecord::Scoping::Named::ClassMethods
#     include ActiveRecord::Persistence
#   end
