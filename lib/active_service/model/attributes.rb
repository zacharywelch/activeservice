module ActiveService
  module Model
    # This module handles attribute methods not provided by ActiveAttr
    module Attributes
      extend ActiveSupport::Concern

      # Apply default scope to any new object
      def initialize(attributes={})  
        attributes ||= {}
        @destroyed = attributes.delete(:_destroyed) || false

        attributes = self.class.default_scope.apply_to(attributes)
        assign_attributes(attributes)
      end

      # Handles missing methods
      #
      # @private
      # def method_missing(method, *args, &blk)
      #   if method.to_s =~ /[?=]$/ || @attributes.include?(method)
      #     # Extract the attribute
      #     attribute = method.to_s.sub(/[?=]$/, '')

      #     # Create a new `attribute` methods set
      #     self.class.attributes(*attribute)

      #     # Resend the method!
      #     send(method, *args, &blk)
      #   else
      #     super
      #   end
      # end

      # @private
      # def respond_to_missing?(method, include_private = false)
      #   method.to_s.end_with?('=') || method.to_s.end_with?('?') || @attributes.include?(method) || super
      # end

      # Assign new attributes to a resource
      #
      # @example
      #   class User < ActiveService::Model
      #   end
      #
      #   user = User.find(1) # => #<User id=1 name="Tobias">
      #   user.assign_attributes(name: "Lindsay")
      #   user.changes # => { :name => ["Tobias", "Lindsay"] }
      def assign_attributes(new_attributes)
        @attributes ||= attributes
        # Use setter methods first
        unset_attributes = self.class.use_setter_methods(self, new_attributes)

        # Then translate attributes of associations into association instances
        parsed_attributes = self.class.parse_associations(unset_attributes)

        # Then merge the parsed_data into @attributes.
        @attributes.merge!(parsed_attributes)
      end
      alias attributes= assign_attributes

      def attributes
        @attributes ||= HashWithIndifferentAccess.new
      end

      # Returns true if attribute is defined
      #
      # @private
      def has_attribute?(attribute_name)
        @attributes.include?(attribute_name.to_sym)
      end      

      # Handles returning data for a specific attribute
      #
      # @private
      def get_attribute(attribute_name)
        @attributes[attribute_name]
      end
      alias attribute get_attribute

      # Return the value of the model `primary_key` attribute
      # def id
      #   @attributes[self.class.primary_key]
      # end    
      
      # Return `true` if other object is an ActiveService::Base and has matching data
      #
      # @private
      def ==(other)
        other.is_a?(ActiveService::Base) && @attributes == other.attributes
      end

      # Delegate to the == method
      #
      # @private
      def eql?(other)
        self == other
      end     
      
      # Delegate to @attributes, allowing models to act correctly in code like:
      #     [ Model.find(1), Model.find(1) ].uniq # => [ Model.find(1) ]
      # @private
      def hash
        @attributes.hash
      end           

      module ClassMethods
        
        # Initialize a single resources
        #
        # @private
        def instantiate_record(klass, record)
          if record.kind_of?(klass)
            record
          else
            klass.new(klass.parse(record))
          end
        end

        # Initialize a collection of resources
        #
        # @private
        def instantiate_collection(klass, data = {})
          collection_parser.new(klass.extract_array(data)).collect! do |record|
            instantiate_record(klass, record)
          end
        end

        # Initialize a collection of resources with raw data from an HTTP request
        #
        # @param [Array] parsed_data
        # @private
        def new_collection(parsed_data)
          instantiate_collection(self, parsed_data)
        end

        # Initialize a new object with the "raw" parsed_data from the parsing middleware
        #
        # @private
        def new_from_parsed_data(parsed_data)
          parsed_data = parsed_data.with_indifferent_access
          new(parse(parsed_data))
        end           

        # Use setter methods of model for each key / value pair in params
        # Return key / value pairs for which no setter method was defined on the model
        #
        # @private
        def use_setter_methods(model, params)
          params ||= {}

          # @note: activeservice won't create attributes automatically
          params.inject({}) do |memo, (key, value)|
            writer = "#{key}="
            if model.respond_to? writer 
              model.send writer, value
            else
              key = key.to_sym if key.is_a? String
              memo[key] = value
            end
            memo
          end
        end
      end
    end
  end
end
