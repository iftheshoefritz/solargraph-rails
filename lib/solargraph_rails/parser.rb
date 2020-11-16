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
      module_names = []
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
          standalone_module = standalone_module_name(line)
          if standalone_module
            Solargraph::Logging.logger.info "found standalone module #{standalone_module}"
            module_names << standalone_module
            next
          end
          inline_module, model_name = namespace_and_model_name(line)
          module_names << inline_module
          if model_name.nil?
            Solargraph::Logging.logger.warn "Unable to find model name in #{line}"
            model_attrs = [] # don't include anything from this file
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
          closure: Solargraph::Pin::Namespace.new(name: module_names.join('::') + model_name),
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

    def standalone_module_name(line)
      line.match(/^\s*module\s*?([A-Z]\w+)/)
      $1
    end

    def namespace_and_model_name(line)
      line
        .match(/class\s*?([A-Z]\w+\:\:)*([A-Z]\w+)\s*<\s*(?:ActiveRecord::Base|ApplicationRecord)/)
      [$1 || '', $2]
    end

    def type_translation
      {
        'decimal' => 'BigDecimal',
        'integer' => 'Integer',
        'date' => 'Date',
        'datetime' => 'ActiveSupport::TimeWithZone',
        'string' => 'String',
        'boolean' => 'Boolean',
        'text' => 'String'
      }
    end
  end
end
