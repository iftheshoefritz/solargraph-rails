module Turbo
  module Native
    module Navigation
      # @return [Boolean]
      def hotwire_native_app?; end

      # @return [Boolean]
      def turbo_native_app?; end
      def recede_or_redirect_to(url, **options); end
      def resume_or_redirect_to(url, **options); end
      def refresh_or_redirect_to(url, **options); end
      def recede_or_redirect_back_or_to(url, **options); end
      def resume_or_redirect_back_or_to(url, **options); end
      def refresh_or_redirect_back_or_to(url, **options); end
    end
  end
end
