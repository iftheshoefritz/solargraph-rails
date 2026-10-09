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

      # Paths inside one gem, relative to its root, to map in addition to its require_paths.
      #
      # @param metagem [Solargraph::Metagem]
      # @return [Array<String>]
      def extra_source_paths(metagem)
        root = metagem.full_path
        app = File.join(root, 'app')
        return [] unless File.directory?(app) && engine?(root, metagem.require_paths)

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
