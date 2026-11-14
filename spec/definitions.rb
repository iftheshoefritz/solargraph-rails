require_relative 'expected_types'
require_relative 'skip_list'
require_relative 'type_members'

class Definitions
  include TypeMembers

  # A bare `Hash` means `Hash[untyped, untyped]`, so it cannot show whether
  # K and V reach a return type. Ask about `Hash{Rational => Complex}`
  # instead, and expect each stand-in where the YAML names its parameter.
  STAND_INS = %w[Rational Complex].freeze

  # rbs 4.0 renamed Array's and Enumerable's Elem to E; activesupport's rbs
  # still says Elem
  RENAMED = { 'Elem' => 'E' }.freeze

  # Solargraph 0.52 and older take only a namespace here, not a type.
  TAKES_TYPE = Solargraph::ApiMap.instance_method(:get_methods).parameters.first.last == :rooted_tag

  def initialize(map, class_name, definition_name, update: false, definitions_file: nil)
    @map = map
    @class_name = class_name
    @definition_name = definition_name
    @update = update
    @definitions_file = definitions_file
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
        instance_tag,
        scope: :instance,
        visibility: %i[public protected private]
      )
  end

  # @return [String] e.g. 'Hash{Rational => Complex}' or 'Array<Rational>'
  def instance_tag
    return class_name if type_params.empty?

    stand_ins = STAND_INS.first(type_params.size)
    return "Hash{#{stand_ins.join(' => ')}}" if class_name == 'Hash'

    "#{class_name}<#{stand_ins.join(', ')}>"
  end

  # @return [Array<String>] e.g. ['K', 'V']
  def type_params
    return [] unless TAKES_TYPE

    @type_params ||= begin
      declarations = map.get_path_pins(class_name).grep(Solargraph::Pin::Namespace)
      names = declarations.map(&:generics).max_by(&:size) || []
      raise "#{class_name} has more type parameters than STAND_INS" if names.size > STAND_INS.size

      names.map { |name| RENAMED.fetch(name, name) }
    end
  end

  # @param types [Array<String>] expected types, e.g. ['Hash{Symbol => generic<V>}']
  # @return [Array<String>] e.g. ['Hash{Symbol => Complex}']
  def with_stand_ins(types)
    types.map do |tag|
      tag.gsub(/generic<(\w+)>/) do |generic|
        index = type_params.index(RENAMED.fetch(Regexp.last_match(1), Regexp.last_match(1)))
        index ? STAND_INS[index] : generic
      end
    end
  end

  # @param types [Array<String>] e.g. ['Hash{Symbol => Complex}']
  # @return [Array<String>] e.g. ['Hash{Symbol => generic<V>}']
  def without_stand_ins(types)
    return types if type_params.empty?

    pattern = /(?<![\w:])(?:#{STAND_INS.first(type_params.size).join('|')})(?![\w:])/
    types.map { |tag| tag.gsub(pattern) { |stand_in| "generic<#{type_params[STAND_INS.index(stand_in)]}>" } }
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
      effective_type = member_tags(pin.typify(map)).sort.uniq
      specified_type = data['types'].sort.uniq
      if effective_type != with_stand_ins(ExpectedTypes.normalize(specified_type, map)).sort.uniq
        if update
          process_potential_update(specified_type, without_stand_ins(effective_type), data, skip)
        elsif !skip
          @incorrect << "#{pin.path} expected #{with_stand_ins(specified_type)}, got: #{effective_type}"
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
