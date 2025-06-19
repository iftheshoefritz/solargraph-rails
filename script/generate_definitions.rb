require File.join(Dir.pwd, ARGV.first, 'config/environment')

require 'method_source'

def _instance_methods(klass, test = klass.new)
  klass
    .instance_methods(true)
    .sort
    .reject { |m| m.to_s.start_with?('_') || (test && !test.respond_to?(m)) }
    .map { |m| klass.instance_method(m) }
end

def own_instance_methods(klass, test = klass.new)
  reject_meth_names = (Module.methods + Module.private_methods + [:to_yaml]).to_set
  _instance_methods(klass, test).select do |m|
    !reject_meth_names.include?(m.name) &&
      m.source_location &&
      m.source_location.first.include?('gem') &&
      m.source_location &&
      m.source_location.first.include?('gem') &&
      !m.source_location.first.include?('/pp-') &&
      m.comment &&
      !m.comment.empty? &&
      m.comment != ':nodoc:'
  end
end

def own_class_methods(klass)
  reject_meth_names = (Module.methods + Module.private_methods + [:to_yaml]).to_set
  class_methods(klass).select do |m|
    !reject_meth_names.include?(m.name) &&
      m.source_location &&
      m.source_location.first.include?('gem') &&
      m.comment &&
      !m.comment.empty? &&
      m.comment != ':nodoc:'
  end
end

def class_methods(klass)
  klass
    .methods(true)
    .sort
    .reject { |m| m.to_s.start_with?('_') || !klass.respond_to?(m) }
    .map { |m| klass.method(m) }
end

def build_report(klass, test: klass.new)
  result = {}
  distribution = {}

  own_class_methods(klass).each do |meth|
    distribution[meth.source_location.first] ||= []
    distribution[meth.source_location.first] << ".#{meth.name}"

    result["#{klass.to_s}.#{meth.name}"] = { types: ['undefined'], skip: false }
  end

  own_instance_methods(klass, test).each do |meth|
    distribution[meth.source_location.first] ||= []
    distribution[meth.source_location.first] << "##{meth.name}"

    result["#{klass.to_s}##{meth.name}"] = { types: ['undefined'], skip: false }
  end

  pp distribution
  result
end

def add_new_methods(klass, test, yaml_filename)
  new_report = build_report(klass, test: test)
  existing_report ={}
  existing_report = YAML.load_file(yaml_filename) if File.exist?(yaml_filename)
  report = {**new_report, **existing_report}
  class_methods, instance_methods = report.partition { |k, _| k.include?('.') }
  class_methods = class_methods.sort_by { |k, _v| k }.to_h
  instance_methods = instance_methods.sort_by { |k, _v| k }.to_h
  report = {**class_methods, **instance_methods}
  File.write(yaml_filename, report.deep_stringify_keys.to_yaml)
end

def core_ext_report(klass, test = klass.new)
  result = {}
  distribution = {}

  class_methods(klass)
    .select(&:source_location)
    .select do |meth|
      loc = meth.source_location.first
      loc.include?('activesupport') && loc.include?('core_ext')
    end
    .each do |meth|
      distribution[meth.source_location.first] ||= []
      distribution[meth.source_location.first] << ".#{meth.name}"

      result["#{klass.to_s}.#{meth.name}"] = {
        types: ['undefined'],
        skip: false
      }
    end

  _instance_methods(klass, test)
    .select(&:source_location)
    .select do |meth|
      loc = meth.source_location.first
      loc.include?('activesupport') && loc.include?('core_ext')
    end
    .each do |meth|
      distribution[meth.source_location.first] ||= []
      distribution[meth.source_location.first] << "##{meth.name}"

      result["#{klass.to_s}##{meth.name}"] = {
        types: ['undefined'],
        skip: false
      }
    end

  result
end

add_new_methods(ActiveRecord::Base, Model.new, '../definitions/activerecord.yml')
add_new_methods(ActionController::Base, false, '../definitions/actioncontroller.yml')
add_new_methods(ActiveJob::Base, false, '../definitions/activejob.yml')

Rails.application.routes.draw do
  add_new_methods(self.class, false, '../definitions/routes.yml')
end

add_new_methods(Rails::Application, false, '../definitions/application.yml')

Rails.application.routes.draw do
  add_new_methods(self.class, false, '../definitions/routes.yml')
end

[
  Array,
  String,
  Time,
  Date,
  Class,
  DateTime,
  File,
  Hash,
  Integer,
  Kernel
].each do |klass|
  test =
    case klass
    when Time
      Time.now
    when Date
      Date.today
    when File
      false
    else
      begin
        klass.new
      rescue StandardError
        false
      end
    end

  add_new_methods(klass, test, "../definitions/core/#{klass.to_s}.yml")
end

# binding.pry
