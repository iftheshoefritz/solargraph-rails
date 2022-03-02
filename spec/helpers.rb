module Helpers
  def load_string(filename, str)
    source = Solargraph::Source.load_string(str, filename)
    api_map.map(source)
    source
  end

  def assert_matches_definitions(map, class_name, defition_name, update: false, print_stats: false)
    definitions = YAML.load_file("spec/definitions/#{defition_name}.yml")

    class_methods = map.get_methods(
      class_name,
      scope: :class, visibility: [:public, :protected, :private]
    )

    instance_methods = map.get_methods(
      class_name,
      scope: :instance, visibility: [:public, :protected, :private]
    )

    skipped = 0
    typed   = 0

    definitions.each do |meth, data|
      next skipped +=1 if data["skip"] && !update

      unless meth.start_with?(".") || meth.start_with?("#")
        meth = meth.gsub(class_name, "")
      end

      pin = if meth.start_with?(".")
        class_methods.find {|p| p.name == meth[1..-1] }
      elsif meth.start_with?("#")
        instance_methods.find {|p| p.name == meth[1..-1] }
      end

      typed += 1 if data["types"] != ["undefined"]

      if pin
        assert_entry_valid(pin, data, update: update)
        data["skip"] = false if update
      elsif update
        skipped += 1
        data["skip"] = true
      else
        raise "#{meth} was not found in completions"
      end
    end

    if update
      File.write("spec/definitions/#{defition_name}.yml", definitions.to_yaml)
    end

    if coverage = Thread.current[:solargraph_arc_coverage]
      total = definitions.keys.size

      coverage << {
        class_name: class_name,
        total:      total,
        covered:    total - skipped,
        typed:      typed,
        percent_covered: percent(total - skipped, total),
        percent_typed:   percent(typed, total)
      }
    end
  end

  def percent(a, b)
    ((a.to_f / b) * 100).round(1)
  end

  def assert_entry_valid(pin, data, update: false)
    effective_type = pin.return_type.map(&:tag)
    specified_type = data["types"]

    if effective_type != specified_type
      if update
        data["types"] = effective_type
      else
        raise "#{pin.path} return type is wrong. Expected #{specified_type}, got: #{effective_type}"
      end
    end
  end

  class Injector
    attr_reader :files
    def initialize(folder)
      @folder = folder
      @files  = []
    end

    def write_file(path, content)
      File.write(path, content)
      @files << path
    end
  end

  def use_workspace(folder, &block)
    injector = Injector.new(folder)
    map      = nil

    Dir.chdir folder do
      yield injector if block_given?
      map = Solargraph::ApiMap.load("./")
      injector.files.each {|f| File.delete(f) }
    end

    map
  end

  def assert_public_instance_method(map, query, return_type, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:instance)
    expect(pin.return_type.map(&:tag)).to eq(return_type)

    yield pin if block_given?
  end

  def assert_class_method(map, query, return_type, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil
    expect(pin.scope).to eq(:class)
    expect(pin.return_type.map(&:tag)).to eq(return_type)

    yield pin if block_given?
  end

  def find_pin(path, map=api_map)
    find_pins(path, map).first
  end

  def find_pins(path, map=api_map)
    map.pins.select {|p| p.path == path }
  end

  def local_pins(map=api_map)
    map.pins.select {|p| p.filename }
  end

  def completion_at(filename, position, map=api_map)
    clip = map.clip_at(filename, position)
    cursor = clip.send(:cursor)
    word = cursor.chain.links.first.word

    Solargraph.logger.debug("Complete: word=#{word}, links=#{cursor.chain.links}")

    clip.complete.pins.map(&:name)
  end

  def completions_for(map, filename, position)
    clip = map.clip_at(filename, position)

    clip.complete.pins.map do |pin|
      [pin.name, pin.return_type.map(&:tag)]
    end.to_h
  end
end
