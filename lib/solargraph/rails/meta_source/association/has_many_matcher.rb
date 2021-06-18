module MetaSource
  module Association
    class HasManyMatcher
      attr_reader :name

      def match?(line)
        line =~ /has_many\s+:([a-z_]*)/
        @name = Regexp.last_match(1)
      end

      def type
        "ActiveRecord::Associations::CollectionProxy<#{name.singularize.camelize}>"
      end
    end
  end
end
