module Solargraph
  module Rails
    class RailsApi
      def self.instance
        @instance ||= self.new
      end

      ANNOTATIONS_DIR = File.join(__dir__, 'annotations')

      # Annotation subdirectories that load only when the bundled gem's
      # version meets the requirement - for types the RBS collection
      # lacks in older versions of that gem, or that older Solargraph
      # versions do not read from it.  Solargraph before 0.53 reads no
      # gem RBS, so they load there whatever the version.
      VERSION_SCOPED_ANNOTATIONS = {
        'actionpack_before_7_2' => ['actionpack', '< 7.2'],
        'solargraph_before_0_60' => ['solargraph', '< 0.60']
      }.freeze

      def extra_source_maps
        @extra_source_maps ||= annotation_paths.to_h do |path|
          code = File.read(path)
          source = Solargraph::Source.load_string(code, path)
          map = Solargraph::SourceMap.map(source)
          [path.delete_prefix("#{ANNOTATIONS_DIR}/").delete_suffix('.rb'), map]
        end
      end

      # @param yard_map [Solargraph::DocMap]
      def global(_doc_map)
        pins = extra_source_maps.values.flat_map(&:pins)
        pins + QueryGenerics.base_pins(pins)
      end

      def local(source_map, ns)
        return [] unless source_map.filename.include?('db/migrate')
        node, _ = Walker.normalize_ast(source_map.source)

        pins = [
          Util.build_module_include(
            ns,
            'ActiveRecord::ConnectionAdapters::SchemaStatements',
            Util.build_location(node, ns.filename)
          ),
          Util.build_module_extend(
            ns,
            'ActiveRecord::ConnectionAdapters::SchemaStatements',
            Util.build_location(node, ns.filename)
          )
        ]

        Solargraph.logger.debug(
          "[Rails][RailsApi] added #{pins.map(&:name)} to #{ns.path}"
        )
        pins
      end

      private

      # @return [Array<String>]
      def annotation_paths
        scoped = VERSION_SCOPED_ANNOTATIONS.select do |_dir, (gem_name, requirement)|
          !gem_rbs_supported? || gem_version_satisfies?(gem_name, requirement)
        end
        Dir[File.join(ANNOTATIONS_DIR, '*.rb')] +
          scoped.keys.flat_map { |dir| Dir[File.join(ANNOTATIONS_DIR, dir, '*.rb')] }
      end

      def gem_rbs_supported?
        Gem::Version.new(Solargraph::VERSION).release >= Gem::Version.new('0.53.0')
      end

      # @param gem_name [String]
      # @param requirement [String]
      def gem_version_satisfies?(gem_name, requirement)
        version = gem_version(gem_name)
        return false unless version

        Gem::Requirement.new(requirement).satisfied_by?(version)
      end

      # @param gem_name [String]
      # @return [Gem::Version, nil]
      def gem_version(gem_name)
        # Solargraph::VERSION carries SOLARGRAPH_FORCE_VERSION on branch builds
        return Gem::Version.new(Solargraph::VERSION).release if gem_name == 'solargraph'

        Gem.loaded_specs[gem_name]&.version
      end
    end
  end
end
