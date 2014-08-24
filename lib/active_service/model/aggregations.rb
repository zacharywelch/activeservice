module ActiveService
  module Model
    # Active Service implements aggregation through a macro-like class method 
    # called +composed_of+ for representing attributes as value objects. This 
    # macro is very similar to Active Record's composed_of macro. For detailed 
    # documentation on this macro please see the Rails documentation at 
    # +http://api.rubyonrails.org/classes/ActiveRecord/Aggregations/ClassMethods.html#method-i-composed_of+
    #
    #   class Customer < ActiveService::Base
    #     composed_of :address, mapping: [ %w(address_street street), %w(address_city city) ]
    #   end
    #
    # The customer class now has the following methods to manipulate the value objects:
    # * <tt>Customer#balance, Customer#balance=(money)</tt>
    # * <tt>Customer#address, Customer#address=(address)</tt>
    #
    # These methods will operate with value objects like the ones described below:
    #
    #  class Address
    #    attr_reader :street, :city
    #    def initialize(street, city)
    #      @street, @city = street, city
    #    end
    #
    #    def close_to?(other_address)
    #      city == other_address.city
    #    end
    #
    #    def ==(other_address)
    #      city == other_address.city && street == other_address.street
    #    end
    #  end      
    module Aggregations
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
  end
end