require 'active_attr'
require 'active_service/persistence'
require 'active_service/field_map'
require 'active_service/aggregations'
require 'active_service/associations'
require 'active_service/reflection'

# = ActiveService 
#
# ActiveService combines the ActiveModel features of ActiveAttr with a 
# persistence mechanism using Typhoeus.

# add field accessor to AttributeDefinition
class ActiveAttr::AttributeDefinition
  # Use field if the source key has a name different than the attribute
  # The field name will be used to map a json key to its attribute and vice-versa   
  def field
    options[:field] || name.to_s
  end
end

module ActiveAttr::Model
  include Persistence
  include ActiveService::Aggregations
  include ActiveService::Reflection
  include ActiveService::Associations
  
  module ClassMethods
    # Returns a map of attributes to fields
    def field_map
      @field_map ||= ActiveService::FieldMap.new(attributes.values)
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end

module ActiveService
  include ActiveAttr  
end
