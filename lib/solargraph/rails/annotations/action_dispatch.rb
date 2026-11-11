module ActionDispatch
  module Flash
    class FlashHash
      # @return [ActionDispatch::Flash::FlashNow]
      def now; end
    end
  end

  module Routing
    class Mapper
      module Resources
        # Still needed after
        # https://github.com/ruby/gem_rbs_collection/pull/1106: without it
        # Solargraph 0.60.4 and 0.61.0 do not resolve generic<T> here, and
        # Rails 7.0 and 7.1 resolve actionpack 6.0 RBS, which lacks it.
        #
        # Returns the block's value, via path_scope's yield.
        #
        # @generic T
        # @yieldreturn [generic<T>]
        # @return [generic<T>]
        def new; end
      end
    end
  end
end
