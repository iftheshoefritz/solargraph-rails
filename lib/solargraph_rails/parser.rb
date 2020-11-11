class Parser
  def initialize(file_names)
    @file_names = file_names
  end

  def parse
    @file_names.each do |file_name|
      log_message :info, "loading from #{file_name}"

      model_attrs = []
      model_name = nil
      line_number = -1
      File.open(file_name).each do |line|
        line_number += 1
        log_message :info, "PROCESSING: #{line}"
        next if skip_line?(line)
        if is_comment?(line)
          col_name, col_type = col_with_type(line)
          log_message :info, "parsed name: #{col_name} type: #{col_type}"

          loc = Solargraph::Location.new(file_name, Solargraph::Range.from_to(line_number, 0, line_number, line.length - 1))
          log_message :info, loc.inspect

          model_attrs << {name: col_name, type: col_type, location: loc}
        else
          model_name = activerecord_model_name(line)
          if model_name.nil?
            log_message :warn, "Unable to find model name in #{line}"
            model_attrs = [] # don't include anything from this model
          end
          break
        end
      end
      log_message :info, "Adding #{model_attrs.count} attributes as pins"
      model_attrs.each do |attr|
        pins << Solargraph::Pin::Method.new(
          name: attr[:name],
          comments: "@return [#{type_translation[attr[:type]]}]",
          location: attr[:location],
          closure: Solargraph::Pin::Namespace.new(name: model_name),
          scope: :instance,
          attribute: true
        )
      end
    end
    log_message(:info, pins)
    log_message(:info, "*********** pin names:")
    log_message(:info, pins.map(&:name))
    pins
  end

  def skip_line?(line)
    skip = line.empty? || line =~ /Schema/ || line =~ /Table/ || line =~ /^\s*#\s*$/ || line =~ /frozen string literal/
    log_message :info, 'skipping' if skip
    skip
  end

  def is_comment?(line)
    line.start_with?('#')
  end

  def col_with_type(line)
    line
      .gsub(/#\s*/, '')
      .split
      .first(2)
  end

  def activerecord_model_name(line)
    line.gsub(/#\s*/, '').match /class\s*?([A-Z]\w+)\s*<\s*(?:ActiveRecord::Base|ApplicationRecord)/
    $1
  end

  # log_message both to STDOUT and Solargraph logger while I am debugging from console
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

