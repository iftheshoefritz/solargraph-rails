# frozen_string_literal: true

require 'pathname'
require 'rbs'
require 'tmpdir'
require_relative 'type_members'

# Definition YAML may name an RBS type alias such as `boolish`, which has no
# YARD spelling. Run each such name through Solargraph as the return type of
# an RBS method typified against the harness's map, so the harness compares
# what Solargraph makes of the alias with what it reports for the method.
module ExpectedTypes
  extend TypeMembers

  # Solargraph 0.57 made RbsMap::Conversions a class that turns an
  # RBS::EnvironmentLoader into pins; earlier releases offer no public way
  # in, so their expectations are compared as written.
  SUPPORTED = Solargraph.const_defined?(:RbsMap) && Solargraph::RbsMap::Conversions.is_a?(Class)

  PROBE_CLASS = 'SolargraphRailsExpectedType'

  # @type [Hash{String => Solargraph::Pin::Method}]
  @probes = {}

  class << self
    # @param tags [Array<String>]
    # @param map [Solargraph::ApiMap]
    # @return [Array<String>]
    def normalize(tags, map)
      return tags unless SUPPORTED

      add_probes(tags.select { |tag| rbs_alias?(tag) } - @probes.keys)
      tags.flat_map { |tag| @probes.key?(tag) ? member_tags(@probes[tag].typify(map)) : [tag] }
    end

    private

    # @param tag [String]
    def rbs_alias?(tag)
      type = RBS::Parser.parse_type(tag)
      type.is_a?(RBS::Types::Alias) && core_environment.type_alias_decls.key?(type.name.absolute!)
    rescue RBS::ParsingError
      false
    end

    # @param tags [Array<String>]
    # @return [void]
    def add_probes(tags)
      return if tags.empty?

      Dir.mktmpdir do |dir|
        methods = tags.each_with_index.map { |tag, i| "  def t#{i}: () -> #{tag}\n" }.join
        File.write(File.join(dir, 'probe.rbs'), "class #{PROBE_CLASS}\n#{methods}end\n")
        loader = RBS::EnvironmentLoader.new
        loader.add(path: Pathname.new(dir))
        pins = Solargraph::RbsMap::Conversions.new(loader: loader).pins
        tags.each_with_index do |tag, i|
          @probes[tag] = pins.find { |pin| pin.path == "#{PROBE_CLASS}#t#{i}" }
        end
      end
    end

    # @return [RBS::Environment]
    def core_environment
      @core_environment ||= RBS::Environment.from_loader(RBS::EnvironmentLoader.new).resolve_type_names
    end
  end
end
