module ActiveService
  module Model
    module Attributes
      class AttributeMap
        attr_reader :attributes

        def initialize(attributes)
          @attributes = attributes.inject({}) do |result, attr|
            result[attr.name] = attr.source
            result
          end
        end

        def by_source
          attributes.invert
        end

        def map(hash, options={})
          mapping = (options[:to] == :source ? attributes : by_source).with_indifferent_access
          hash.inject({}) do |result, (k, v)|
            key = mapping.has_key?(k) ? mapping[k] : k
            result[key] = v
            result
          end
        end
      end
    end
  end
end
