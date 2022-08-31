module Solargraph
  module Rails
    class Schema
      ColumnData = Struct.new(:type, :ast)

      RUBY_TYPES = {
        decimal: 'BigDecimal',
        float: 'BigDecimal',
        integer: 'Integer',
        date: 'Date',
        datetime: 'ActiveSupport::TimeWithZone',
        string: 'String',
        boolean: 'Boolean',
        text: 'String',
        jsonb: 'Hash',
        json: 'Hash',
        bigint: 'Integer',
        uuid: 'String',
        inet: 'IPAddr',
        citext: 'String',
        binary: 'String',
        timestamp: 'ActiveSupport::TimeWithZone'
      }

      def self.instance
        @instance ||= self.new
      end

      def self.reset
        @instance = nil
      end

      def initialize
        @schema_present = File.exist?('db/schema.rb')
      end

      def process(source_map, ns)
        return [] unless @schema_present
        return [] unless Model.valid_filename?(source_map.filename)

        table = find_table(source_map, ns)

        return [] unless table

        pins =
          table.map do |column, data|
            Util.build_public_method(
              ns,
              column,
              types: [RUBY_TYPES.fetch(data.type.to_sym)],
              location: Util.build_location(data.ast, 'db/schema.rb')
            )
          end

        if pins.any?
          Solargraph.logger.debug(
            "[Rails][Schema] added #{pins.map(&:name)} to #{ns.path}"
          )
        end
        pins
      end

      private

      def schema
        @extracted_schema ||=
          begin
            ast = NodeParser.parse(File.read('db/schema.rb'), 'db/schema.rb')
            extract_schema(ast)
          end
      end

      def find_table(source_map, ns)
        table_name = nil
        walker = Walker.from_source(source_map.source)
        walker.on :send, [:self, :table_name=, :str] do |ast|
          table_name = ast.children.last.children.first
        end
        walker.walk

        # always use explicit table name if present
        return schema[table_name] if table_name

        infer_table_names(ns).filter_map { |table_name| schema[table_name] }.first
      end

      def infer_table_names(ns)
        table_name = ns.name.tableize
        if ns.namespace.present?
          [ns.path.tableize.tr('/', '_'), table_name]
        else
          [table_name]
        end
      end

      def extract_schema(ast)
        schema = {}

        walker = Walker.new(ast)
        walker.on :block, [:send, nil, :create_table] do |ast, query|
          table_name = ast.children.first.children[2].children.last
          schema[table_name] = {}

          query.on :send, %i[lvar t] do |column_ast|
            name = column_ast.children[2].children.last
            type = column_ast.children[1]

            next if type == :index
            next if type == :check_constraint
            schema[table_name][name] = ColumnData.new(type, column_ast)
          end
        end

        walker.walk
        schema
      end
    end
  end
end
