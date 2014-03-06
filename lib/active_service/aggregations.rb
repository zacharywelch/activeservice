module ActiveService::Aggregations
  extend ActiveSupport::Concern

  module ClassMethods    
    def composed_of(value, options = {})
      options.assert_valid_keys(:class_name, :mapping)
      
      name       = value.id2name
      class_name = options[:class_name] || name.classify
      mapping    = options[:mapping]    || [ name, name ]
      mapping    = [ mapping ] unless mapping.first.is_a?(Array)

      reader_method(name, class_name, mapping)
      writer_method(name, class_name, mapping)
    end

    private

    def reader_method(name, class_name, mapping)
      define_method(name) do
        if instance_variable_get("@#{name}").nil?
          attrs = mapping.inject(
            ActiveSupport::HashWithIndifferentAccess.new
            ) do |result, (source, target)|
            
            result[target] = read_attribute(source)
            result
          end
          object = class_name.constantize.new(attrs)
          instance_variable_set("@#{name}", object)
        end
        instance_variable_get("@#{name}")
      end
    end

    def writer_method(name, class_name, mapping)
      define_method("#{name}=") do |value|
        if value.nil?
          mapping.each { |pair| self[pair.first] = nil }
        else
          mapping.each { |pair| self[pair.first] = value.send(pair.last) }
        end

        instance_variable_set("@#{name}", value)
      end
    end
  end  
end