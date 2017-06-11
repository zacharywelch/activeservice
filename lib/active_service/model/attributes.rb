require 'active_service/model/attributes/nested_attributes'
require 'active_service/model/attributes/attribute_map'
require 'active_service/model/attributes/serializer'

module ActiveService
  module Model
    # This module handles attribute methods not provided by ActiveAttr
    module Attributes
      extend ActiveSupport::Concern
      include ActiveService::Model::Attributes::NestedAttributes

      # Initialize a new object with data
      #
      # @param [Hash] attributes The attributes to initialize the object with
      # @option attributes [Boolean] :_destroyed
      #
      # @example
      #   class User < ActiveService::Base
      #     attribute :name
      #   end
      #
      #  User.new(name: "Tobias")
      #  # => #<User name="Tobias">
      #
      #  User.new do |u|
      #    u.name = "Tobias"
      #  end
      #  # => #<User name="Tobias">
      def initialize(attributes={})
        attributes ||= {}
        @destroyed = attributes.delete(:_destroyed) || false
        @owner_path = attributes.delete(:_owner_path)

        attributes = self.class.default_scope.apply_to(attributes)
        assign_attributes(attributes) && apply_defaults
        yield self if block_given?
      end

      # Handles missing methods
      #
      # @private
      def method_missing(method, *args, &blk)
        name = method.to_s.chop
        if method.to_s =~ /[?=]$/ && has_association?(name)
          (class << self; self; end).send(:define_method, method) do |value|
            @attributes[:"#{name}"] = value
          end
          send method, *args, &blk
        else
          super
        end
      end

      # @private
      def respond_to_missing?(method, include_private = false)
        method.to_s =~ /[?=]$/ && has_association?(method.to_s.chop) || super
      end

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
        associations = self.class.parse_associations(unset_attributes)
        # Then merge the associations into @attributes
        @attributes.merge!(associations)
      end
      alias attributes= assign_attributes

      def attributes
        @attributes ||= HashWithIndifferentAccess.new
      end

      # Returns true if attribute is defined
      #
      # @private
      def has_attribute?(attribute_name)
        self.class.attribute_names.include?(attribute_name.to_s)
      end

      # @private
      def has_nested_attributes?(attributes_name)
        return false unless attributes_name.to_s.match(/_attributes/)
        associations = self.class.associations.values.flatten.map { |a| a[:name] }
        associations.include?(attributes_name.to_s.gsub("_attributes", "").to_sym)
      end

      # Handles returning data for a specific attribute
      #
      # @private
      def get_attribute(attribute_name)
        @attributes[attribute_name]
      end

      # Returns complete list of attributes and included associations
      #
      # @private
      def serialized_attributes
        Serializer.new(self).serialize
      end

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

        # Initialize a single resource
        #
        # @private
        def instantiate_record(klass, record)
          if record.kind_of?(klass)
            record
          else
            klass.new(klass.parse(record)) do |resource|
              resource.send :clear_changes_information
            end
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
          instantiate_record(self, parsed_data)
        end

        # Use setter methods of model for each key / value pair in params
        # Return key / value pairs for which no setter method was defined on the model
        #
        # @note Activeservice won't create attributes automatically
        # @private
        def use_setter_methods(model, params)
          params ||= {}

          params.inject({}) do |memo, (key, value)|
            writer = "#{key}="
            if model.respond_to?(writer) && (model.has_attribute?(key) || model.has_nested_attributes?(key))
              model.send writer, value
            else
              key = key.to_sym if key.is_a? String
              memo[key] = value
            end
            memo
          end
        end

        # Returns a mapping of attributes to fields
        #
        # ActiveService can map fields from a response to attributes defined on a
        # model. <tt>attribute_map</tt> translates source fields to their model
        # attributes and vice-versa during HTTP requests.
        def attribute_map
          @attribute_map ||= ActiveService::Model::Attributes::AttributeMap.new(attributes.values)
        end
      end
    end
  end
end
