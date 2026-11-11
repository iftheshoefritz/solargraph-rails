module Turbo
  module Native
    module Navigation
      # @return [Boolean]
      def hotwire_native_app?; end

      # @return [Boolean]
      def turbo_native_app?; end

      # @return [void]
      def recede_or_redirect_to(url, **options); end

      # @return [void]
      def resume_or_redirect_to(url, **options); end

      # @return [void]
      def refresh_or_redirect_to(url, **options); end

      # @return [void]
      def recede_or_redirect_back_or_to(url, **options); end

      # @return [void]
      def resume_or_redirect_back_or_to(url, **options); end

      # @return [void]
      def refresh_or_redirect_back_or_to(url, **options); end
    end
  end
end
