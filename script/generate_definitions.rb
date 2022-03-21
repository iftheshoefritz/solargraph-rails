require File.join(Dir.pwd, ARGV.first, 'config/environment')

class Model < ActiveRecord::Base
end

def own_instance_methods(klass, test = klass.new)
  (instance_methods(klass, test) - Object.methods).select do |m|
    m.source_location && m.source_location.first.include?('gem')
  end
end

def own_class_methods(klass)
  (class_methods(klass) - Object.methods).select do |m|
    m.source_location && m.source_location.first.include?('gem')
  end
end

def instance_methods(klass, test = klass.new)
  klass
    .instance_methods(true)
    .sort
    .reject { |m| m.to_s.start_with?('_') || (test && !test.respond_to?(m)) }
    .map { |m| klass.instance_method(m) }
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

  instance_methods(klass, test)
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

report = build_report(ActiveRecord::Base, test: Model.new)
File.write('activerecord.yml', report.deep_stringify_keys.to_yaml)

report = build_report(ActionController::Base)
File.write('actioncontroller.yml', report.deep_stringify_keys.to_yaml)

report = build_report(ActiveJob::Base)
File.write('activejob.yml', report.deep_stringify_keys.to_yaml)

Rails.application.routes.draw do
  report = build_report(self.class, test: false)
  File.write('routes.yml', report.deep_stringify_keys.to_yaml)
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

  report = core_ext_report(klass, test = test)
  File.write("#{klass.to_s}.yml", report.deep_stringify_keys.to_yaml)
end

# binding.pry
