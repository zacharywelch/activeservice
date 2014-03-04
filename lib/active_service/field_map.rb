module ActiveService
  class FieldMap
    attr_reader :data

    def initialize(attributes)
      @data = attributes.inject({}) do |result, attr|
        result[attr.name] = attr.field
        result
      end
    end

    def by_source
      data.invert
    end

    def by_target
      data
    end

    def map(hash, options={})
      mapping = (options[:by] == :target ? by_target : by_source)
      hash.inject({}) do |result, (k, v)|
        result[mapping[k]] = v
        result
      end
    end
  end
end