module ActiveService
  module Model
    # This module handles resource data parsing at the model level (after the parsing middleware)
    module Parse
      extend ActiveSupport::Concern

      # Convert into a hash of request parameters, based on `include_root_in_json`.
      #
      # @todo add dirty changes
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        self.class.to_params(self.attributes)
      end

      module ClassMethods
        # Parse data before assigning it to a resource, based on `parse_root_in_json`.
        #
        # @param [Hash] data
        # @private
        def parse(data)
          data = data.with_indifferent_access
          if parse_root_in_json? && root_element_included?(data)
            data = json_api_format? ? 
              data.fetch(parsed_root_element).first : 
              data.fetch(parsed_root_element) { data }
          end
          attribute_map.map(data)
        end

        # @private
        # @todo add filtered attributes and associations
        def to_params(attributes)
          filtered_attributes = attributes.dup.symbolize_keys          
          filtered_attributes.merge!(embeded_params(attributes))          
          if include_root_in_json?
            if json_api_format?
              { included_root_element => [filtered_attributes] }
            else
              { included_root_element => filtered_attributes }
            end
          else
            filtered_attributes
          end
        end


        # @private
        # TODO: Handle has_one
        def embeded_params(attributes)
          associations[:has_many].select { |a| attributes.include?(a[:data_key])}.compact.inject({}) do |hash, association|
            params = attributes[association[:data_key]].map(&:to_params)
            next if params.empty?
            if association[:class_name].constantize.include_root_in_json?
              root = association[:class_name].constantize.root_element
              hash[association[:data_key]] = params.map { |n| n[root] }
            else
              hash[association[:data_key]] = params
            end
            hash
          end
        end

        # Return or change the value of `include_root_in_json`
        #
        # @example
        #   class User
        #     include Her::Model
        #     include_root_in_json true
        #   end
        def include_root_in_json(value, options = {})
          @include_root_in_json = value
          @include_root_in_json_format = options[:format]
        end        

        # Return or change the value of `parse_root_in_json`
        #
        # @example
        #   class User < ActiveService::Base
        #     parse_root_in_json true
        #   end
        #
        #   class User < ActiveService::Base
        #     parse_root_in_json true, format: :active_model_serializers
        #   end
        #
        #   class User < ActiveService::Base
        #     parse_root_in_json true, format: :json_api
        #   end
        def parse_root_in_json(value, options = {})
          @parse_root_in_json = value
          @parse_root_in_json_format = options[:format]
        end

        # Return or change the value of `request_new_object_on_build`
        #
        # @example
        #   class User < ActiveService::Base
        #     request_new_object_on_build true
        #   end
        def request_new_object_on_build(value = nil)
          @request_new_object_on_build = value
        end

        # Return or change the value of `root_element`. Always defaults to the base name of the class.
        #
        # @example
        #   class User < ActiveService::Base
        #     parse_root_in_json true
        #     root_element :huh
        #   end
        #
        #   user = User.find(1) # { :huh => { :id => 1, :name => "Tobias" } }
        #   user.name # => "Tobias"
        def root_element(value = nil)
          if value.nil?
            if json_api_format?
              @root_element ||= model_name.collection.to_sym
            else
              @root_element ||= model_name.element.to_sym
            end
          else
            @root_element = value.to_sym
          end
        end

        # Define the collection parser that will be used to map resource collections
        #
        # @example
        #  class User < ActiveService::Base
        #    collection_parser PaginationCollection
        #  end
        #
        # @param [Symbol] value
        def collection_parser(value = nil)
          @collection_parser ||= begin
            superclass.collection_parser if superclass.respond_to?(:collection_parser)
          end

          return @collection_parser unless value
          @collection_parser = value
        end        

        # @private
        def root_element_included?(data)
          data.keys.to_s.include? @root_element.to_s
        end

        # @private
        def included_root_element
          include_root_in_json? == true ? root_element : include_root_in_json?
        end

        # Extract an array from the request data
        #
        # @example
        #   # with parse_root_in_json true, :format => :active_model_serializers
        #   class User < ActiveService::Base
        #     parse_root_in_json true, :format => :active_model_serializers
        #   end
        #
        #   users = User.all # { :users => [ { :id => 1, :name => "Tobias" } ] }
        #   users.first.name # => "Tobias"
        #
        #   # without parse_root_in_json
        #   class User < ActiveService::Base
        #   end
        #
        #   users = User.all # [ { :id => 1, :name => "Tobias" } ]
        #   users.first.name # => "Tobias"
        #
        # @private
        def extract_array(data)
          if data.is_a?(Hash) && data.keys.size == 1
            data.values.first
          else
            data
          end
        end

        # @private
        def pluralized_parsed_root_element
          parsed_root_element.to_s.pluralize.to_sym
        end

        # @private
        def parsed_root_element
          parse_root_in_json? == true ? root_element : parse_root_in_json?
        end

        # @private
        def active_model_serializers_format?
          @parse_root_in_json_format == :active_model_serializers || (superclass.respond_to?(:active_model_serializers_format?) && superclass.active_model_serializers_format?)
        end

        # @private
        def json_api_format?
          @parse_root_in_json_format == :json_api || (superclass.respond_to?(:json_api_format?) && superclass.json_api_format?)
        end

        # @private
        def request_new_object_on_build?
          @request_new_object_on_build || (superclass.respond_to?(:request_new_object_on_build?) && superclass.request_new_object_on_build?)
        end

        # @private
        def include_root_in_json?
          @include_root_in_json || (superclass.respond_to?(:include_root_in_json?) && superclass.include_root_in_json?)
        end        

        # @private
        def parse_root_in_json?
          @parse_root_in_json || (superclass.respond_to?(:parse_root_in_json?) && superclass.parse_root_in_json?)
        end
      end
    end
  end
end
