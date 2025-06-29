require 'logger'
require 'rails'
require_relative 'definitions'

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
    Definitions.new.assert_matches_definitions(map, class_name, definition_name, update: update)
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

  def rails_workspace(&block)
    rails_version = ENV.fetch('MATRIX_RAILS_VERSION')
    rails_major_version = rails_version.split('.').first.to_i
    folder = "./spec/rails#{rails_major_version}"

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

  def assert_method(map, query, return_type, args: {}, scope: query.include?("#") ? :instance : :class, &block)
    pin = find_pin(query, map)
    expect(pin).to_not be_nil, "Expected #{query} to exist, but it doesn't"
    expect(pin.scope).to eq(scope), "Expected #{query} to have scope #{scope}, but it has #{pin.scope}"

    pin_return_type = pin.return_type
    pin_return_type = pin.typify map if pin_return_type.undefined?
    pin_return_type = pin.probe map if pin_return_type.undefined?
    expect(pin_return_type.map(&:tag)).to eq(return_type)

    args.each_pair do |name, type|
      expect(parameter = pin.parameters.find { _1.name == name.to_s }).to_not be_nil, "expected #{query} param #{name} to exist, but it doesn't"
      expect(parameter.return_type.tag).to eq(type), "expected #{query} param #{name} to return #{type} but it returns #{parameter.return_type.tag}"
    end
    pin.parameters.each do |param|
      expect(args).to have_key(param.name.to_sym), "expected #{query} param #{param.name} to be expected, but it isn't"
      # TODO: Is this necesseray? It should already be expected earlier by the arg.each_pair block
      expect(real_type = param.return_type.tag).to eq(args[param.name.to_sym]), "expected #{query} param #{param.name} to return #{args[param.name.to_sym]} but it returns #{real_type}"
    end
  end

  def assert_public_instance_method(map, query, return_type, args: {}, &block)
    assert_method(map, query, return_type, args: args, scope: :instance, &block)
  end

  def assert_class_method(map, query, return_type, args: {}, &block)
    assert_method(map, query, return_type, args: args, scope: :class, &block)
  end

  def find_pin(path, map = api_map)
    find_pin_by_path(map.pins, path, map)
  end

  def find_pin_by_path(pins, path, map)
    if pins.empty?
      return nil
    else
      top_level_pins = pins.select { |p| p.path == path }
      if top_level_pins.empty?
        scope = nil
        scope = :class
        class_name, meth, rest = path.split('.')
        raise "Did not understand path #{path}" unless rest.nil?
        if meth.nil?
          class_name, meth, rest = class_name.split('#')
          raise "Did not understand path #{path}" unless rest.nil?
          scope = :instance
        end
        return map.get_method_stack(class_name, meth, scope: scope).first
      end
      return_pin = top_level_pins.find do |pin|
        pin_return_type = pin.return_type
        pin_return_type = pin.typify map if pin_return_type.undefined?
        pin_return_type = pin.probe map if pin_return_type.undefined?
        pin_return_type.defined?
      end
      return_pin ||= top_level_pins.first
      return_pin
    end
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
