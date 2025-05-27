module ActionDispatch
  module Flash
    class FlashHash
      # @return [ActionDispatch::Flash::FlashNow]
      def now; end
    end
  end

  module Routing
    class Mapper
      include ActionDispatch::Routing::Mapper::Base
      include ActionDispatch::Routing::Mapper::HttpHelpers
      include ActionDispatch::Routing::Mapper::Redirection
      include ActionDispatch::Routing::Mapper::Scoping
      include ActionDispatch::Routing::Mapper::Concerns
      include ActionDispatch::Routing::Mapper::Resources
      include ActionDispatch::Routing::Mapper::CustomUrls
    end

    class RouteSet
      # @yieldself [ActionDispatch::Routing::Mapper]
      def draw; end
    end
  end
end
