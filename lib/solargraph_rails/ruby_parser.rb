module SolargraphRails
  class RubyParser
    def initialize(file_contents: '')
      @lines = file_contents.lines
      @comment_handlers = []
      @class_handlers = []
      @module_handlers = []
    end

    def on_comment(&blk)
      @comment_handlers << blk
    end

    def on_class(&blk)
      @class_handlers << blk
    end

    def on_module(&blk)
      @module_handlers << blk
    end

    def parse
      @lines
        .map(&:strip)
        .each do |line|
        if is_comment?(line)
          comment_content = line.gsub(/#\s*/, '')
          @comment_handlers.each { |handler| handler.call(comment_content) }
        end

        if is_class?(line)
          line.scan(/([A-Z]\w*)\:\:/).flatten.each do |inline_module_name|
            @module_handlers.each { | handler| handler.call(inline_module_name) }
          end
          line.match(/class\s+(?:.*?(?:\:\:))*([A-Z]\w*)\s*(?:<\s*([A-Z]\w*))?/)
          klass_name, superklass_name = $1, $2
          @class_handlers.each { |handler| handler.call(klass_name, superklass_name) }
        end

        if is_module?(line)
          module_name = line.match(/^\s*module\s*?([A-Z]\w+)/)[1]
          @module_handlers.each { |handler| handler.call(module_name) }
        end
      end
    end

    private

    def is_comment?(line)
      line =~ (/^\s*#/)
    end

    def is_class?(line)
      line =~ /^[^#]?.*?class\s+?[A-Z]/
    end

    def is_module?(line)
      line =~ (/^\s*module\s*?([A-Z]\w+)/)
    end
  end
end
