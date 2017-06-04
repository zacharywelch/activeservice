module ActiveService
  module Model
    module Attributes
      # This class symbolizes a resource's attributes and included associations.
      # Modified attributes are used when it's for a patch request
      class Serializer
        attr_reader :resource

        def initialize(resource)
          @resource = resource
        end

        # Convert resource and its associations into a symbolized hash
        def serialize
          deep_serialize(resource)
        end

        private

        # Symbolize attributes and any nested objects
        # @private
        def deep_serialize(resource)
          attributes(resource).merge(association_attributes(resource))
                              .deep_symbolize_keys
        end

        # @private
        def attributes(resource)
          if changes_only?
            resource.modified_attributes.tap do |hash|
              hash[:id] = resource.id if hash.present?
            end
          else
            resource.attributes
          end
        end

        # @private
        def association_attributes(resource)
          resource.class.association_names.each_with_object({}) do |name, hash|
            value = case association = resource.attributes[name]
                    when ActiveService::Collection, Array
                      association.map { |a| deep_serialize(a) }.reject(&:empty?)
                    when ActiveService::Base
                      deep_serialize(association)
                    end
            hash[name] = value if value.present?
          end
        end

        # Return `true` if only modified attributes should be used
        # @private
        def changes_only?
          resource.persisted? &&
          resource.class.method_for(:update) == :patch
        end
      end
    end
  end
end
