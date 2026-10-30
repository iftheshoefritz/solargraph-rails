# frozen_string_literal: true

module Solargraph
  module Rails
    # Rails engines keep code under app/, which Zeitwerk loads instead of
    # require. Map the roots Rails::Engine::Configuration#paths autoloads.
    class Engine
      # app/* and app/*/concerns, as the "app" path's glob.
      APP_ROOTS = '{*,*/concerns}'

      # Excluded from the "app" path's eager loading.
      NON_RUBY_APP_DIRS = %w[assets javascript].freeze

      MAILER_PREVIEWS = 'test/mailers/previews'

      # @return [Solargraph::Rails::Engine]
      def self.instance
        @instance ||= new
      end

      # @param root [String] the gem's root directory
      # @param require_paths [Array<String>] the gem's require paths, relative to root
      # @return [Array<String>] paths inside the gem, relative to root, to map beyond require_paths
      def extra_source_paths(root:, require_paths:)
        app = File.join(root, 'app')
        return [] unless File.directory?(app) && engine?(root, require_paths)

        roots = Dir.glob(File.join(app, APP_ROOTS)).select { |dir| File.directory?(dir) }
        roots = roots.map { |dir| dir.delete_prefix("#{app}/") } - NON_RUBY_APP_DIRS
        roots = roots.sort.map { |dir| File.join('app', dir) }
        roots.push(MAILER_PREVIEWS) if File.directory?(File.join(root, MAILER_PREVIEWS))
        roots
      end

      private

      # @param root [String]
      # @param require_paths [Array<String>]
      # @return [Boolean] whether the gem's required code subclasses Rails::Engine
      def engine?(root, require_paths)
        require_paths.any? do |path|
          Dir.glob(File.join(root, path, '**', '*.rb')).any? do |file|
            File.read(file).match?(/<\s*(?:::)?Rails::Engine\b/)
          end
        end
      end
    end
  end
end
