# = ActiveAttr
# 
# ActiveAttr provides most of the ActiveModel functionality in ActiveService. 
# Here we patch ActiveAttr with additional features needed by ActiveService 

module ActiveAttr::Attributes
  extend ActiveSupport::Concern  
  include ActiveModel::AttributeMethods  

  module ClassMethods

    alias_method :attribute_without_values, :attribute

    def attribute(name, options = {})
      attribute_without_values(name, options)
      attribute_with_values(name, options[:values]) if options[:values]
      self
    end

    private

    def attribute_with_values(name, values)
      values = Hash[values.map { |key| [key, key] }] unless values.is_a?(Hash)      

      values.each do |key, value|
        define_method "#{key}?" do
          attributes[name] == value
        end
      end

      values.each do |key, value|
        scope "#{key}", -> { where(:"#{name}" => value) }
      end
    end
  end
end