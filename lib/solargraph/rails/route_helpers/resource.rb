module Solargraph
  module Rails
    class RouteHelpers
      # A static copy of ActionDispatch::Routing::Mapper::Resources::Resource: the names and paths of a `resources`
      # call.
      class Resource
        # @param api_only [Boolean]
        # @return [Array<Symbol>]
        def self.default_actions(api_only)
          if api_only
            %i[index create show update destroy]
          else
            %i[index create new show update destroy edit]
          end
        end

        # @return [String]
        attr_reader :controller

        # @return [String]
        attr_reader :path

        # @return [Symbol]
        attr_reader :param

        # @param entities [Symbol, String]
        # @param api_only [Boolean]
        # @param shallow [Boolean, nil]
        # @param options [Hash{Symbol => Object}]
        def initialize(entities, api_only, shallow, options)
          @name = entities.to_s
          @path = (options[:path] || @name).to_s
          @controller = (options[:controller] || @name).to_s
          @as = options[:as]
          @param = (options[:param] || :id).to_sym
          @shallow = shallow
          @api_only = api_only
          @only = options[:only]
          @except = options[:except]
        end

        # @return [Array<Symbol>]
        def actions
          available = @only ? Array(@only).map(&:to_sym) : self.class.default_actions(@api_only)
          @except ? available - Array(@except).map(&:to_sym) : available
        end

        # @return [String]
        def name
          (@as || @name).to_s
        end

        # @return [String]
        def plural
          name
        end

        # @return [String]
        def singular
          name.singularize
        end
        alias member_name singular

        # Uncountable names get an `_index` suffix so the collection and member helpers differ, e.g. news_index_path.
        #
        # @return [String]
        def collection_name
          singular == plural ? "#{plural}_index" : plural
        end

        # @return [String]
        def collection_scope
          path
        end

        # @return [String]
        def member_scope
          "#{path}/:#{param}"
        end
        alias shallow_scope member_scope

        # @param new_path [String]
        # @return [String]
        def new_scope(new_path)
          "#{path}/#{new_path}"
        end

        # @return [Symbol]
        def nested_param
          :"#{singular}_#{param}"
        end

        # @return [String]
        def nested_scope
          "#{path}/:#{nested_param}"
        end

        # @return [Boolean]
        def shallow?
          @shallow ? true : false
        end

        # @return [Boolean]
        def singleton?
          false
        end
      end

      # A static copy of ActionDispatch::Routing::Mapper::Resources::SingletonResource: a `resource` call, which has
      # no index and no :id.
      class SingletonResource < Resource
        # @param api_only [Boolean]
        # @return [Array<Symbol>]
        def self.default_actions(api_only)
          if api_only
            %i[show create update destroy]
          else
            %i[show create update destroy new edit]
          end
        end

        # @param entities [Symbol, String]
        # @param api_only [Boolean]
        # @param shallow [Boolean, nil]
        # @param options [Hash{Symbol => Object}]
        def initialize(entities, api_only, shallow, options)
          super
          @controller = (options[:controller] || plural).to_s
        end

        # @return [String]
        def plural
          name.pluralize
        end

        # @return [String]
        def singular
          name
        end
        alias member_name singular
        alias collection_name singular

        # @return [String]
        def member_scope
          path
        end

        # @return [String]
        def nested_scope
          path
        end

        # @return [Boolean]
        def singleton?
          true
        end
      end
    end
  end
end
