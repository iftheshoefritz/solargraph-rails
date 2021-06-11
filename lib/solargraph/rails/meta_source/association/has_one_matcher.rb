module MetaSource
  module Association
    class HasOneMatcher
      attr_reader :name

      def match?(line)
        line =~ /has_one\s+:([a-z_]*)/
        @name = Regexp.last_match(1)
      end

      def type
        name.camelize
      end
    end
  end
end
