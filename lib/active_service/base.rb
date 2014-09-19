require 'active_service/model'

module ActiveService
  # ActiveService::Base is the main class for mapping web services to models.
  #
  # For an outline of Active Service's features, see its +README+.
  #
  # @example
  #   class Person < ActiveService::Base
  #     self.base_uri = "https://api.people.com"
  #     attribute :name
  #   end
  #
  #   @person = Person.new(:name => "Foo")
  #   @person.save
  class Base
    include ActiveService::Model

    # Returns true if attribute_name is
    # * in resource attributes
    # * an association
    #
    # @private
    def has_key?(attribute_name)
      has_attribute?(attribute_name) ||
      has_association?(attribute_name)
    end

    # Returns
    # * the value of the attribute_name attribute if it's in orm data
    # * the resource/collection corresponding to attribute_name if it's an association
    #
    # @private
    def [](attribute_name)
      get_attribute(attribute_name) ||
      get_association(attribute_name)
    end

    # @private
    def singularized_resource_name
      self.class.model_name.singular
    end    
  end
end