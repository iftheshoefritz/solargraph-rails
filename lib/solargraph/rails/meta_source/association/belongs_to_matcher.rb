module MetaSource
  module Association
    class BelongsToMatcher
      attr_reader :name

      def match?(line)
        line =~ /belongs_to\s+:([a-z_]*)/
        @name = Regexp.last_match(1)
      end

      def type
        name&.camelize
      end
    end
  end
end
