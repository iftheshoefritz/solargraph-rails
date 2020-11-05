require 'rails/all'
require 'solargraph_rails/version'
require 'solargraph'

module SolargraphRails
  class DynamicAttributes < Solargraph::Convention::Base
    def global yard_map
      log_message(:info, "#{'*'*100} running convention!")
      log_message(:info, "#{'*'*25} attempting to require models")
      Dir[Rails.root.join 'app', 'models', '*.rb')].each { |file| require file }
      Solargraph::Environ.new(pins: parse_pins)
    end

    private

    def parse_pins
      # TODO: use all descendants instead of the last
      klass = ActiveRecord::Base.descendants.select { |model_klass| !model_klass.abstract_class? }.first
      log_message(:info, "#{'*'*50} + adding #{klass}")
      pins = []
      ## TODO: find a way to do resolution that can handle namespaces:
      source = Solargraph::Source.load(Rails.root.join('app', 'models', "#{klass.name.underscore}.rb"))

      map = Solargraph::SourceMap.map(source)
      class_location = map.first_pin(klass.name).location

      log_message(:info, klass.columns.map(&:name))
      klass.columns.each do |col|
        log_message(:info, "*"*25 + "adding #{col.name}")
        pins << Solargraph::Pin::Method.new(
          name: col.name,
          comments: "@return [#{type_translation[col.type]}]",
          location: class_location,
          scope: :instance,
          attribute: true
        )
      end
      puts pins
      pins
    end

    # log_message both to STDOUT and Solargraph logger while I am diagnosing from console
    # and client
    def log_message(level, msg)
      puts "[#{level}] #{msg}"
      Solargraph::Logging.logger.send(level, msg)
    end

    def type_translation
      {
        decimal: 'Decimal',
        integer: 'Int',
        date: 'Date',
        datetime: 'DateTime',
        string: 'String',
        boolean: 'Bool'
      }
    end
  end
end


Solargraph::Convention.register SolargraphRails::DynamicAttributes
