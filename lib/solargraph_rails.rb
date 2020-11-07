require 'solargraph_rails/version'
require 'solargraph'

module SolargraphRails
  class DynamicAttributes < Solargraph::Convention::Base
    def global yard_map
      puts "solarails caller stack:"
      puts caller
      log_message(:info, "******************************* running convention!")
      Solargraph::Environ.new(pins: parse_models)
    end

    private

    def parse_models
      pins = []

      klass_name = 'MyBook'
      klass_name_underscore = 'my_book'
      # doesn't like Rails.root here:
      file_name = File.join(Dir.pwd, 'app', 'models', "#{klass_name_underscore}.rb")

      log_message :info, "loading from #{file_name}"

      line_number = -1
      File.open(file_name).each do |line|
        line_number += 1
        log_message :info, "PROCESSING: #{line}"
        next if skip_line?(line)
        break if end_comments?(line)
        col_name, col_type = col_with_type(line)
        log_message :info, "parsed name: #{col_name} type: #{col_type}"

        loc = Solargraph::Location.new(file_name, Solargraph::Range.from_to(line_number, 0, line_number, line.length - 1))
        log_message :info, loc.inspect

        pins << Solargraph::Pin::Method.new(
          name: col_name,
          comments: "@return [#{type_translation[col_type]}]",
          location: loc,
          closure: Solargraph::Pin::Namespace.new(name: klass_name),
          scope: :instance,
          #attribute: true
        )
      end
      log_message(:info, pins)
      log_message(:info, "*********** pin names:")
      log_message(:info, pins.map(&:name))
      pins
    end

    def skip_line?(line)
      skip = line.empty? || line =~ /Schema/ || line =~ /Table/ || line =~ /^\s*#\s*$/
      log_message :info, 'skipping' if skip
      skip
    end

    def end_comments?(line)
      !line.start_with?('#')
    end

    def col_with_type(line)
      line
        .gsub(/#\s*/, '')
        .split
        .first(2)
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
