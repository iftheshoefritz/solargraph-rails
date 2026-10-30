require_relative 'skip_list'
require_relative 'type_members'

class Definitions
  include TypeMembers

  def initialize(map, class_name, definition_name, update: false)
    @map = map
    @class_name = class_name
    @definition_name = definition_name
    @update = update
  end

  def inspect
    to_s
  end

  def assert_matches_definitions
    @update = true if ENV['FORCE_UPDATE'] == 'true'
    @allow_improvements = true if ENV['ALLOW_IMPROVEMENTS'] == 'true' || solargraph_version.start_with?('branch-')

    definitions = YAML.load_file(definitions_file)

    @skipped = 0
    @typed = 0
    @incorrect = []
    @missing = []
    @congrats = []

    definitions.each do |meth, data|
      next if rbs_too_old?(data)

      process_single_definition(meth, data)
    end

    File.write("spec/definitions/#{definition_name}.yml", definitions.to_yaml) if update

    if @missing.any?
      raise <<~STR
        The following methods could not be found despite being listed in #{definition_name}.yml:
        #{@missing}
      STR
    end

    if @incorrect.any?
      raise <<~STR
        The return types of these methods did not match #{definition_name}.yml:
          #{@incorrect.join("\n  ")}
      STR
    end

    @congrats.each do |message|
      $stdout.puts message
    end

    total = definitions.keys.size

    return if ENV['PRINT_STATS'].nil?

    puts(
      {
        class_name: class_name,
        total: total,
        covered: total - @skipped,
        typed: @typed,
        percent_covered: percent(total - @skipped, total),
        percent_typed: percent(@typed, total)
      }
    )
  end

  private

  def definitions_file
    @definitions_file ||= "spec/definitions/#{definition_name}.yml"
  end

  def instance_methods
    @instance_methods ||=
      map.get_methods(
        class_name,
        scope: :instance,
        visibility: %i[public protected private]
      )
  end

  def class_methods
    @class_methods ||= map.get_methods(
      class_name,
      scope: :class,
      visibility: %i[public protected private]
    )
  end

  def solargraph_version
    solargraph_force_ci_version = ENV.fetch('CI', nil) && ENV.fetch('MATRIX_SOLARGRAPH_VERSION', nil)
    return solargraph_force_ci_version if solargraph_force_ci_version

    Solargraph::VERSION
  end

  # Some declarations only take their current form from a given rbs onward -
  # e.g. rbs 4.0 renamed Enumerable's type parameter from Elem to E.
  def rbs_too_old?(data)
    return false unless data['min_rbs']
    return false unless defined?(RBS::VERSION)
    return false unless Gem::Version.new(RBS::VERSION) < Gem::Version.new(data['min_rbs'])

    @skipped += 1
    true
  end

  def process_single_definition(meth, data)
    meth = meth.gsub(class_name, '') unless meth.start_with?('.', '#')
    # @type [Array<Solargraph::Pin::Base>]
    pins =
      if meth.start_with?('.')
        class_methods.select { |p| p.name == meth[1..] }
      elsif meth.start_with?('#')
        instance_methods.select { |p| p.name == meth[1..] }
      else
        raise "Bad method name in definitions: #{meth} in #{definitions_file}"
      end
    # @type [Array<Solargraph::Pin::Base>] pins
    relevant_pins = pins.select { |p| p.path == pins.first.path }
    meh_types = %w[BasicObject Object undefined]
    good_pins, meh_pins = relevant_pins.partition do |p|
      return_type_tags = member_tags(p.typify(map))
      meh_types.none? { |meh_type| return_type_tags.include? meh_type }
    end
    # try hard to get a high quality and stable result
    pin = (good_pins.sort_by { |p| member_tags(p.typify(map)).sort } +
           meh_pins.sort_by { |p| member_tags(p.typify(map)).sort }).first
    skip = false
    @typed += 1 if data['types'] != ['undefined']
    already_removed = false
    if data['removed_in'] && data['removed_in'].to_f <= rails_major_and_minor_version.to_f
      skip = true
      already_removed = true
    end
    not_added_yet = false
    if data['added_in'] && (data['added_in'].to_f > rails_major_and_minor_version.to_f)
      skip = true
      not_added_yet = true
    end
    if SkipList.applies?(data['skip'], solargraph_version, rails_major_and_minor_version)
      skip = true
      @skipped += 1
    end
    # Completion is found, but marked as skipped
    if pin
      typified = pin.typify(map)
      effective_type = member_tags(typified).sort.uniq
      specified_type = data['types'].sort.uniq
      literal_class_type = literal_class_tags(typified)
      effective_type = literal_class_type if literal_class_type == specified_type
      if effective_type != specified_type
        if update
          process_potential_update(specified_type, effective_type, data, skip)
        elsif !skip
          @incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
        end
      elsif skip
        rbs_pin = pin.respond_to?(:source) && pin.source == :rbs
        if update
          # rbs signatures cover several Rails versions, so an rbs pin does not
          # show that a method removed or not yet added in this one exists
          remove_skip(data) unless rbs_pin && (already_removed || not_added_yet)
        elsif rbs_pin
          # rbs-only definitions may cover multiple versions of Rails and cause false alarms
          nil
        elsif !@allow_improvements
          @incorrect << <<~STR
            #{pin.path} is marked as skipped in #{definitions_file} for #{solargraph_version} on Rails #{rails_major_and_minor_version}, but is actually present and correct - see #{pin.inspect}.
            Consider setting skip=false
          STR
        else
          @congrats << "#{pin.path} is now present and correct, despite being marked as skipped"
        end
      end
    elsif update && !already_removed && !not_added_yet
      @skipped += 1
      add_to_skip(data)
    elsif skip
      nil
    else
      @missing << meth
    end
  end

  # Solargraph with castwide/solargraph#1451 types an RBS literal return
  # such as `-> false` as `false`; this lets it match an expected Boolean.
  #
  # @param type [Solargraph::ComplexType]
  # @return [Array<String>]
  def literal_class_tags(type)
    type = type.simplify_literals if type.respond_to?(:simplify_literals)
    member_tags(type).sort.uniq
  end

  def process_potential_update(specified_type, effective_type, data, skip)
    if specified_type == ['undefined']
      if !effective_type.include?('BasicObject') && !effective_type.include?('Object')
        # sounds like a better type
        data['types'] = effective_type
      elsif !skip
        add_to_skip(data)
      end
    elsif specified_type == ['Object']
      if !effective_type.include?('BasicObject')
        # sounds like a better type
        data['types'] = effective_type
      elsif !skip
        add_to_skip(data)
      end
    elsif specified_type == ['BasicObject']
      # sounds like a better type
      data['types'] = effective_type
    elsif !skip
      # @incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
      add_to_skip(data)
    end
  end

  def add_to_skip(data)
    SkipList.add(data, solargraph_version, rails_major_and_minor_version, matrix_rails_versions)
  end

  def remove_skip(data)
    SkipList.remove(data, solargraph_version, rails_major_and_minor_version, matrix_rails_versions)
  end

  def rails_major_and_minor_version
    Rails.version.split('.')[0..1].join('.')
  end

  def matrix_rails_versions
    @matrix_rails_versions ||= SkipList.matrix_rails_versions(solargraph_version)
  end

  def percent(num_a, num_b)
    ((num_a.to_f / num_b) * 100).round(1)
  end

  attr_reader :map, :class_name, :definition_name, :update
end
