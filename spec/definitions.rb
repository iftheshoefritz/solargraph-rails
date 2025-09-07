class Definitions
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
    @allow_improvements = true if ENV['ALLOW_IMPROVEMENTS'] == 'true' || solargraph_version == 'branch-master'

    definitions = YAML.load_file(definitions_file)

    @skipped = 0
    @typed = 0
    @incorrect = []
    @missing = []
    @congrats = []

    definitions.each do |meth, data|
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
      return_type_tags = p.typify(map).map(&:tag)
      meh_types.none? { |meh_type| return_type_tags.include? meh_type }
    end
    # try hard to get a high quality and stable result
    pin = (good_pins.sort_by { |p| p.typify(map).map(&:tag).sort } +
           meh_pins.sort_by { |p| p.typify(map).map(&:tag).sort }).first
    skip = false
    @typed += 1 if data['types'] != ['undefined']
    rails_major_and_minor_version = Rails.version.split('.')[0..1].join('.')
    already_removed = false
    if data['removed_in']
      rails_major_and_minor_version = Rails.version.split('.')[0..1].join('.')
      if data['removed_in'].to_f <= rails_major_and_minor_version.to_f
        skip = true
        already_removed = true
      end
    end
    not_added_yet = false
    if data['added_in'] && (data['added_in'].to_f > rails_major_and_minor_version.to_f)
      skip = true
      not_added_yet = true
    end
    if data['skip'] == true ||
#       data['skip'] == Solargraph::VERSION || # in case of branches relying on existing version excludes
       data['skip'] == solargraph_version || # in case of branches with specific excludes
       (data['skip'] == 'branch-master' && solargraph_version.start_with?('branch-')) ||
#       (data['skip'].respond_to?(:include?) && data['skip'].include?(Solargraph::VERSION)) ||
       (data['skip'].respond_to?(:include?) && data['skip'].include?(solargraph_version))
      (data['skip'].respond_to?(:include?) && data['skip'].include?('branch-master')
       && solargraph_version.start_with?('branch-'))
      skip = true
      @skipped += 1
    end
    # Completion is found, but marked as skipped
    if pin
      effective_type = pin.typify(map).map(&:tag).sort.uniq
      specified_type = data['types'].sort.uniq
      if effective_type != specified_type
        if update
          process_potential_update(specified_type, effective_type, data, skip)
        elsif !skip
          @incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
        end
      # rbs-only definitions may cover multiple versions of Rails and cause false alarms
      elsif skip && !(pin.respond_to?(:source) && pin.source == :rbs)
        if update
          remove_skip(data)
        elsif !@allow_improvements
          @incorrect << <<~STR
            #{pin.path} is marked as skipped in #{definitions_file} for #{solargraph_version}, but is actually present and correct - see #{pin.inspect}.
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
    data['skip'] = [] unless data['skip'].is_a?(Array)
    data['skip'] << solargraph_version
    data['skip'].sort!.uniq!
  end

  def remove_skip(data)
    if data['skip'].is_a?(Array)
      data['skip'].delete(solargraph_version)
      data['skip'].sort!.uniq!
      data['skip'] = false if data['skip'].empty?
    else
      data['skip'] = false
    end
  end

  def percent(num_a, num_b)
    ((num_a.to_f / num_b) * 100).round(1)
  end

  attr_reader :map, :class_name, :definition_name, :update
end
