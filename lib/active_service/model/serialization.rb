module ActiveService
  module Model
    # This module monkey patches ActiveModel's basic serialization functionality 
    # and excludes include_root_in_json to keep API.setup conventions consistent      
    module Serialization
      extend ActiveSupport::Concern
      include ActiveModel::Serialization

      included do
        extend ActiveModel::Naming
      end

      # Returns a hash representing the model. 
      # See ActiveModel::Serializers::JSON for documentation
      def as_json(options = nil)
        root = if options && options.key?(:root)
          options[:root]
        else
          self.class.include_root_in_json?
        end

        if root
          root = self.class.model_name.element if root == true
          { root => serializable_hash(options) }
        else
          serializable_hash(options)
        end
      end

      # Sets the model +attributes+ from a JSON string. Returns +self+.
      # See ActiveModel::Serializers::JSON for documentation
      def from_json(json, include_root=self.class.include_root_in_json?)
        hash = ActiveSupport::JSON.decode(json)
        hash = hash.values.first if include_root
        self.attributes = hash
        self
      end      
    end
  end
end