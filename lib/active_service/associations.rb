require 'active_support/concern'
require 'active_service/associations/builder/association'
require 'active_service/associations/builder/has_many'
require 'active_service/associations/builder/belongs_to'

module ActiveService
  module Associations
    extend ActiveSupport::Concern
    
    module ClassMethods
    
      def belongs_to(name, options = {})
        Builder::BelongsTo.build(self, name, options)
      end

      def has_many(name, options = {})
        association_id_sym = "#{name}_id".to_sym
        Builder::HasMany.build(self, name, options)
      end

      def has_one(name, options = {})
        Builder::HasOne.build(self, name, options)
      end

      def defines_belongs_to_finder_method(method_name, association_model, finder_key)
        ivar_name = :"@#{method_name}"

        if method_defined?(method_name)
          instance_variable_set(ivar_name, nil)
          remove_method(method_name)
        end

        define_method(method_name) do
          if instance_variable_defined?(ivar_name)
            instance_variable_get(ivar_name)
          elsif attributes.include?(method_name)
            attributes[method_name]
          elsif association_id = send(finder_key)
            instance_variable_set(ivar_name, association_model.find(association_id))
          end
        end
      end

      def defines_has_many_finder_method(method_name, association_model)
        ivar_name = :"@#{method_name}"

        define_method(method_name) do
          if instance_variable_defined?(ivar_name)
            instance_variable_get(ivar_name)
          elsif attributes.include?(method_name)
            attributes[method_name]
          elsif !new_record?
            instance_variable_set(ivar_name, association_model.find(:all, 
              :params => {:"#{self.class.model_name.element}_id" => self.id}))
          else
            instance_variable_set(ivar_name, self.class.collection_parser.new)
          end
        end
      end

      def defines_has_one_finder_method(method_name, association_model)
        ivar_name = :"@#{method_name}"

        define_method(method_name) do
          if instance_variable_defined?(ivar_name)
            instance_variable_get(ivar_name)
          elsif attributes.include?(method_name)
            attributes[method_name]
          elsif association_model.respond_to?(:singleton_name)
            instance_variable_set(ivar_name, association_model.find(
              :params => {:"#{self.class.model_name.element}_id" => self.id}))
          else
            instance_variable_set(ivar_name, association_model.find(:one, 
              :from => "/#{self.class.model_name.collection}/#{self.id}/#{method_name}"))
          end
        end
      end
    end
  end
end
