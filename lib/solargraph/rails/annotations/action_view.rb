module ActionView
  class Base
    include ActionDispatch::Routing::RouteSet::MountedHelpers
  end
end
