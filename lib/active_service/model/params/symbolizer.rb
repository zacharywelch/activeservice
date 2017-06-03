module ActiveService
  module Model
    module Params
      class Symbolizer
        def initialize(attributes)
          @attributes = attributes.dup
        end

        def symbolize
          deep_symbolize(@attributes)
        end

        private

        # @private
        def deep_symbolize(attributes)
          attributes.each_with_object({}) do |(key, value), hash|
            hash[key.to_sym] = symbolize_value(value)
          end
        end

        # @private
        def symbolize_value(value)
          case value
          when ActiveService::Base
            deep_symbolize(value.attributes)
          when Hash
            deep_symbolize(value)
          when Array
            value.map { |v| symbolize_value(v) }
          else
            value
          end
        end
      end
    end
  end
end
