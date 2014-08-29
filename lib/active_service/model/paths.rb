module ActiveService
  module Model
    module Paths
      extend ActiveSupport::Concern
      # Return a path based on the collection path and a resource data
      #
      # @example
      #   class User < ActiveService::Base
      #     collection_path "/hodors"
      #   end
      #
      #   User.find(1) # Fetched via GET /hodors/1
      #
      # @param [Hash] params An optional set of additional parameters for
      #   path construction. These will not override attributes of the resource.
      def request_path(params = {})
        self.class.build_request_path(params.merge(attributes.dup))
      end

      module ClassMethods

        # Define the primary key field that will be used to find and save records
        #
        # @example
        #  class User < ActiveService::Base
        #    primary_key 'UserId'
        #  end
        #
        # @param [Symbol] value
        def primary_key(value = nil)
          @primary_key ||= begin
            superclass.primary_key if superclass.respond_to?(:primary_key)
          end

          return @primary_key unless value
          @primary_key = value.to_sym
        end

        # Defines a custom collection path for the resource
        #
        # @example
        #  class User < ActiveService::Base
        #    collection_path "/hodors"
        #  end
        def collection_path(path = nil)
          if path.nil?
            @collection_path ||= root_element.to_s.pluralize
          else
            @collection_path = path
            @element_path = "#{path}/:id"
          end
        end

        # Defines a custom element path for the resource
        #
        # @example
        #  class User < ActiveService::Base
        #    element_path "/hodors/:id"
        #  end
        def element_path(path = nil)
          if path.nil?
            @element_path ||= "#{root_element.to_s.pluralize}/:id"
          else
            @element_path = path
          end
        end

        # Return a custom path based on the collection path and variable parameters
        #
        # @private
        def build_request_path(path = nil, parameters = {})
          parameters = parameters.try(:with_indifferent_access)

          unless path.is_a?(String)
            parameters = path.try(:with_indifferent_access) || parameters
            path =
              if parameters.include?(primary_key) && parameters[primary_key] && !parameters[primary_key].kind_of?(Array)
                element_path.dup
              else
                collection_path.dup
              end

            # Replace :id with our actual primary key
            path.gsub!(/(\A|\/):id(\Z|\/)/, "\\1:#{primary_key}\\2")
          end

          path.gsub(/:([\w_]+)/) do
            # Look for :key or :_key, otherwise raise an exception
            value = $1.to_sym
            parameters.delete(value) || 
            parameters.delete(:"_#{value}") || 
            raise(ActiveService::Errors::PathError.new("Missing :_#{$1} parameter to build the request path. Path is `#{path}`. Parameters are `#{parameters.symbolize_keys.inspect}`.", $1))
          end
        end

        # @private
        def build_request_path_from_string_or_symbol(path, params={})
          path.is_a?(Symbol) ? "#{build_request_path(params)}/#{path}" : path
        end
      end
    end
  end
end
