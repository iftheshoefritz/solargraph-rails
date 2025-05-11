module Helpers
  def load_string(filename, str)
    source = Solargraph::Source.load_string(str, filename)
    api_map.map(source)
    source
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

      typed += 1 if data['types'] != ['undefined']
      skipped += 1 if data['skip']

      # Completion is found, but marked as skipped
      if pin && data['skip']
        puts <<~STR
          #{class_name}#{meth} is marked as skipped in #{definitions_file}, but is actually present.
          Consider setting skip=false
        STR
      elsif pin
        effective_type = pin.typify(map).items.map(&:rooted_tag).sort.uniq
        specified_type = data['types']

        if effective_type != specified_type
          if update
            data['types'] = effective_type
          else
            incorrect << "#{pin.path} expected #{specified_type}, got: #{effective_type}"
          end
        end
        data['skip'] = false if update
      elsif update
        skipped += 1
        data['skip'] = true
      elsif data['skip']
        next
      else
        missing << meth
      end
    end

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

    File.write("spec/definitions/#{definition_name}.yml", definitions.to_yaml) if update

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

    def write_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      @files << path
    end
  end

  def use_workspace(folder, &block)
    injector = Injector.new(folder)
    map = nil

    Dir.chdir folder do
      yield injector if block_given?
      map = Solargraph::ApiMap.load_with_cache('./', STDERR)
      injector.files.each { |f| File.delete(f) }
    end

    map
  end

  def assert_public_instance_method(map, query, return_type, args: nil, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil, -> { "Could not find method in api_map via #{query}" }
    expect(pin.scope).to eq(:instance)
    pin_return_type = pin.return_type
    pin_return_type = pin.probe map if pin_return_type.undefined?
    expect(pin_return_type.map(&:tag)).to eq(return_type) # , ->() { "Was expecting return_type=#{return_type} while processing #{pin.inspect}, got #{pin.return_type.map(&:tag)}" }
    unless args.nil?
      args.each_pair do |name, type|
        expect(parameter = pin.parameters.find { _1.name == name.to_s }).to_not be_nil
        expect(parameter.return_type.tag).to eq(type)
      end
      pin.parameters.each do |param|
        expect(args).to have_key(param.name.to_sym)
        expect(param.return_type.tag).to eq(args[param.name.to_sym])
      end
    end

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
