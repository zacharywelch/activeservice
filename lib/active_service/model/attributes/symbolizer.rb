module ActiveService
  module Model
    module Attributes
      # This class symbolizes a resource's attributes and included associations.
      # Modified attributes are used when it's for a patch request
      class Symbolizer
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        # Convert resource and its associations into a symbolized hash
        def symbolize
          deep_symbolize(resource)
        end

        private

        # Symbolize attributes and any nested objects
        # @private
        def deep_symbolize(resource)
          resource.attributes.each_with_object({}) do |(key, value), hash|
            if symbolize?(resource, key)
              hash[key.to_sym] = symbolize_value(value)
            end
          end
        end

        # @private
        def symbolize_value(value)
          case value
          when ActiveService::Base
            deep_symbolize(value)
          when Hash
            value.deep_symbolize_keys
          when Array, ActiveService::Collection
            value.map { |v| symbolize_value(v) }
          else
            value
          end
        end

        # @private
        def symbolize?(resource, attribute)
          return true unless changes_only?
          return true if resource.changed.include?(attribute)
          return true if association = resource.get_association(attribute) and
                         association.is_a?(ActiveService::Base) and
                         association.changed?
          return true if association = resource.get_association(attribute) and
                         association.is_a?(Array) and
                         association.any?(&:changed?)
        end

        # Return `true` if only modified attributes should be used
        # @private
        def changes_only?
          resource.persisted? && resource.class.method_for(:update) == :patch
        end
      end
    end
  end
end
