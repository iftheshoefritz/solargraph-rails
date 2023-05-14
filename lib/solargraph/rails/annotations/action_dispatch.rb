module ActionDispatch
  module Routing
    class RouteSet
      # @!method draw(&block)
      #   @yieldself [Mapper]
    end

    class Mapper
      include Resources
      include Concerns
      include Scoping
      include Redirection
      include HttpHelpers
      include Base
    end
  end

  module Flash
    class FlashHash
      # @return [ActionDispatch::Flash::FlashNow]
      def now; end
    end
  end
end
