module Helpers
  def load_string(filename, str)
    source = Solargraph::Source.load_string(str, filename)
    api_map.map(source)
    source
  end

  def add_to_skip(data)
    unless data['skip'].is_a?(Array)
      data['skip'] = []
    end
    data['skip'] << Solargraph::VERSION
    data['skip'].sort!.uniq!
  end

  def remove_skip(data)
    if data['skip'].is_a?(Array)
      data['skip'].delete(Solargraph::VERSION)
      data['skip'].sort!.uniq!
      if data['skip'].empty?
        data['skip'] = false
      end
    else
      data['skip'] = false
    end
  end

  def assert_matches_definitions(map, class_name, definition_name, update: false)
    if ENV['FORCE_UPDATE'] == 'true'
      update = true
    end
    definitions_file = "spec/definitions/#{definition_name}.yml"
    definitions = YAML.load_file(definitions_file)

    class_methods =
      map.get_methods(
        class_name,
        scope: :class,
        visibility: %i[public protected private]
      )

    instance_methods =
      map.get_methods(
        class_name,
        scope: :instance,
        visibility: %i[public protected private]
      )

    skipped = 0
    typed = 0
    incorrect = []
    missing = []

    definitions.each do |meth, data|
      meth = meth.gsub(class_name, '') unless meth.start_with?('.') || meth.start_with?('#')

      pin =
        if meth.start_with?('.')
          class_methods.find { |p| p.name == meth[1..-1] }
        elsif meth.start_with?('#')
          instance_methods.find { |p| p.name == meth[1..-1] }
        end

      skip = false
      typed += 1 if data['types'] != ['undefined']
      if data['skip'] == true ||
         data['skip'] == Solargraph::VERSION ||
         (data['skip'].respond_to?(:include?) && data['skip'].include?(Solargraph::VERSION))
        skip = true
        skipped += 1
      end

      # Completion is found, but marked as skipped
      if pin
        effective_type = pin.typify(map).map(&:tag).sort.uniq
        specified_type = data['types']

        if effective_type != specified_type
          if update
            if effective_type == ['undefined']
              add_to_skip(data)
            elsif specified_type.include?('undefined') || specified_type.include?('BasicObject')
              # sounds like a better type
              data['types'] = effective_type
            elsif !skip
              # incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
              add_to_skip(data)
            end
          elsif !skip
            incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
          end
        elsif skip
          if update
            remove_skip(data)
          else
            incorrect << <<~STR
            #{class_name}#{meth} is marked as skipped in #{definitions_file} for #{Solargraph::VERSION}, but is actually present and correct.
            Consider setting skip=false
          STR
          end
        end
      elsif update
        skipped += 1
        add_to_skip(data)
      elsif data['skip']
        next
      else
        missing << meth
      end
    end


    File.write("spec/definitions/#{definition_name}.yml", definitions.to_yaml) if update

    if missing.any?
      raise <<~STR
        The following methods could not be found despite being listed in #{definition_name}.yml:
        #{missing}
      STR
    end

    if incorrect.any?
      raise <<~STR
        The return types of these methods did not match #{definition_name}.yml:
          #{incorrect.join("\n  ")}
      STR
    end

    total = definitions.keys.size

    if ENV['PRINT_STATS'] != nil
      puts(
        {
          class_name: class_name,
          total: total,
          covered: total - skipped,
          typed: typed,
          percent_covered: percent(total - skipped, total),
          percent_typed: percent(typed, total)
        }
      )
    end
  end

  def percent(a, b)
    ((a.to_f / b) * 100).round(1)
  end

  class Injector
    attr_reader :files
    def initialize(folder)
      @folder = folder
      @files = []
    end

    def solargraph_version
      Solargraph::VERSION.split('.')[0..1].join('.').to_f
    end

    def write_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      @files << path
      # Older Solargraph versions store relative paths; return those
      # so we can fetch them by the same names later
      if solargraph_version < 0.51
        "./" + path
      else
        File.expand_path(path)
      end
    end
  end

  def use_workspace(folder, &block)
    injector = Injector.new(folder)
    map = nil

    Dir.chdir folder do
      yield injector if block_given?
      if Solargraph::ApiMap.respond_to?(:load_with_cache)
        map = Solargraph::ApiMap.load_with_cache('./', STDERR)
      else
        map = Solargraph::ApiMap.load('./')
      end
      injector.files.each { |f| File.delete(f) }
    end

    map
  end

  def assert_public_instance_method(map, query, return_type, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:instance)
    pin_return_type = pin.return_type
    pin_return_type = pin.typify map if pin_return_type.undefined?
    pin_return_type = pin.probe map if pin_return_type.undefined?
    expect(pin_return_type.map(&:tag)).to eq(return_type) # , ->() { "Was expecting return_type=#{return_type} while processing #{pin.inspect}, got #{pin.return_type.map(&:tag)}" }

    yield pin if block_given?
  end

  def assert_class_method(map, query, return_type, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:class)
    expect(pin.return_type.map(&:tag)).to eq(return_type)

    yield pin if block_given?
  end

  def find_pin(path, map = api_map)
    find_pins(path, map).first
  end

  def find_pins(path, map = api_map)
    map.pins.select { |p| p.path == path }
  end

  def local_pins(map = api_map)
    map.pins.select { |p| p.filename }
  end

  def completion_at(filename, position, map = api_map)
    clip = map.clip_at(filename, position)
    cursor = clip.send(:cursor)
    word = cursor.chain.links.first.word

    Solargraph.logger.debug(
      "Complete: word=#{word}, links=#{cursor.chain.links}"
    )

    clip.complete.pins.map(&:name)
  end

  def completions_for(map, filename, position)
    clip = map.clip_at(filename, position)

    clip.complete.pins.map { |pin| [pin.name, pin.return_type.map(&:tag)] }.to_h
  end
end
