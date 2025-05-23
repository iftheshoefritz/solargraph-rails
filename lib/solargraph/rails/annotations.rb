# The following comments fill some of the gaps in Solargraph's understanding of
# Rails apps. Since they're all in YARD, they get mapped in Solargraph but
# ignored at runtime.
#
# This file is automatically included in the Solargraph workspace when
# solargrph-rails is configured as a plugin.
#
# To make additions, you can add a similar file anywhere in your
# project, as long as it gets included in the workspace maps. It's
# recommended that you keep it in a standalone file instead of pasting
# it into an existing one.  If your additions are generally useful,
# please contribute it back via PR to the solargraph-rails project.
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
