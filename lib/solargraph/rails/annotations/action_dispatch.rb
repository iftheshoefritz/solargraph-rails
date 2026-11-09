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
        # Remove once ruby/gem_rbs_collection#1106 is released and the
        # collection revision is bumped:
        # https://github.com/ruby/gem_rbs_collection/pull/1106
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
