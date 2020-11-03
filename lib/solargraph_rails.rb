require 'solargraph_rails/version'
require 'solargraph'

module SolargraphRails
  class DynamicAttributes < Solargraph::Convention::Base
    def global yard_map
      Solargraph::Logging.logger.info "*"*100 + 'running convention!'
      puts "*"*100
      Solargraph::Environ.new(pins: parse_pins)
    end

    private

    def parse_pins
      klasses = [MyBook] # use ActiveRecord::Base.descendants to find the real list
      klass = ApplicationRecord.descendants.first
      Solargraph::Logging.logger.info "*"*50 + "adding #{klass}"
      pins = []
      ## TODO: find a way to do resolution that can handle namespaces:
      source = Solargraph::Source.load(Rails.root.join('app', 'models', "#{klass.name.underscore}.rb"))
      ## somehow this ^ line returns an error when I run `Solargraph::ApiMap.load(Rails.root)` in the console, but if I run the line itself directly in the console, no problem.

      map = Solargraph::SourceMap.map(source)
      class_location = map.first_pin(klass.name).location

      # TODO: pins seems like it might not be a plain array
      # in the example from CastWide which returned:
      #
      #     Solargraph::SourceMap.load_string(%(
      #       class Foo; end
      #     )).pins
      #  Inside SourceMap it looks like pins is created like so:
      #
      #   @pins, @locals = Parser.map(source)
      #
      # TODO: what are the pins that Parser.map returns?
      #         answer: returns [Array(Array<Pin::Base>, Array<Pin::Base>)]
      # gem source: https://github.com/whitequark/parser/

      pins << klass.columns.map do |col|
        Solargraph::Pin::Method.new(
          name: col.name,
          comments: "@return [#{type_translation[col.type]}]",
          location: class_location
        )
      end
      puts pins
      pins
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
