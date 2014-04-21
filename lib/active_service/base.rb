require 'active_service/reflection'
require 'active_service/associations'
require 'active_service/aggregations'
require 'active_service/persistence'
require 'active_service/field_map'
require 'active_service/request'

module ActiveService

  class Base
    # ActiveService::Base is the main class for mapping web services to models.
    #
    # For an outline of Active Service's features, see its +README+.

    include ActiveAttr::Model
    include ActiveService::Reflection
    include ActiveService::Associations
    include ActiveService::Aggregations
    include ActiveService::Persistence
    include ActiveService::Request

    # Returns a mapping of attributes to fields
    # 
    # ActiveService can map fields from a response to attributes defined on a 
    # model. <tt>field_map</tt> returns a mapping of those 
    # attributes and fields that is used when sending/receiving data using 
    # web services.
    def self.field_map
      @field_map ||= ActiveService::FieldMap.new(attributes.values)
    end
  end
end
