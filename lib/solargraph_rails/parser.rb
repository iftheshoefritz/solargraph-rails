# frozen_string_literal: true

module SolargraphRails
  class Parser
    attr_reader :contents, :path

    def initialize(path, contents)
      @path = path
      @contents = contents
    end

    def parse
      model_attrs = []
      model_name = nil
      line_number = -1
      contents.lines do |line|
        line_number += 1
        Solargraph::Logging.logger.info "PROCESSING: #{line}"

        next if skip_line?(line)

        if is_comment?(line)
          col_name, col_type = col_with_type(line)
          Solargraph::Logging.logger.info "suspected attribute name: #{col_name} type: #{col_type}"
          if type_translation.keys.include?(col_type)
            Solargraph::Logging.logger.info "parsed name: #{col_name} type: #{col_type}"

            loc = Solargraph::Location.new(path, Solargraph::Range.from_to(line_number, 0, line_number, line.length - 1))
            Solargraph::Logging.logger.info loc.inspect

            model_attrs << {name: col_name, type: col_type, location: loc}
          else
            Solargraph::Logging.logger.info "could not find annotation in comment"
            next
          end
        else
          model_name = activerecord_model_name(line)
          if model_name.nil?
            Solargraph::Logging.logger.warn "Unable to find model name in #{line}"
            model_attrs = [] # don't include anything from this model
          end
          break
        end
      end
      Solargraph::Logging.logger.info "Adding #{model_attrs.count} attributes as pins"
      model_attrs.map do |attr|
        Solargraph::Pin::Method.new(
          name: attr[:name],
          comments: "@return [#{type_translation[attr[:type]]}]",
          location: attr[:location],
          closure: Solargraph::Pin::Namespace.new(name: model_name),
          scope: :instance,
          attribute: true
        )
      end
    end

    def skip_line?(line)
      skip = line.strip.empty? || line =~ /Schema/ || line =~ /Table/ || line =~ /^\s*#\s*$/ || line =~ /frozen string literal/
      Solargraph::Logging.logger.info 'skipping' if skip
      skip
    end

    def is_comment?(line)
      line =~ (/^\s*#/)
    end

    def col_with_type(line)
      line
        .gsub(/#\s*/, '')
        .gsub(':', '')
        .gsub(/\(|,|\)/, '')
        .split
        .first(2)
    end

    def activerecord_model_name(line)
      line.gsub(/#\s*/, '').match /class\s*?([A-Z]\w+)\s*<\s*(?:ActiveRecord::Base|ApplicationRecord)/
      $1
    end

    def type_translation
      {
        'decimal' => 'Decimal',
        'integer' => 'Int',
        'date' => 'Date',
        'datetime' => 'DateTime',
        'string' => 'String',
        'boolean' => 'Bool',
        'text' => 'String'
      }
    end
  end
end
