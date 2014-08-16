module ActiveService
  module Model
    # This module handles attribute methods not provided by ActiveAttr
    module Attributes
      extend ActiveSupport::Concern

      # Apply default scope to any new object
      def initialize(attributes={})                
        @destroyed = attributes.delete(:_destroyed) || false
        super self.class.default_scope.apply_to(attributes)
      end

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

        # Returns true if attribute is defined
        #
        # @private
        def has_attribute?(attribute_name)
          @attributes.include?(attribute_name.to_sym)
        end      
      end
    end
  end
end
