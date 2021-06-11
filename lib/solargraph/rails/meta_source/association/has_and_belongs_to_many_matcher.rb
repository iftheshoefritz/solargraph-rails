module MetaSource
  module Association
    class HasAndBelongsToManyMatcher
      attr_reader :name

      def match?(line)
        line =~ /has_and_belongs_to_many\s+:([a-z_]*)/
        @name = Regexp.last_match(1)
      end

      def type
        "Array<#{name.singularize.camelize}>"
      end
    end
  end
end
