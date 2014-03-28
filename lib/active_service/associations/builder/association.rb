require 'active_support/core_ext/class/attribute'

module ActiveService
  module Associations
    module Builder
      
      class Association
        
        class_attribute :valid_options
        self.valid_options = [:class_name]

        class_attribute :macro

        attr_reader :model, :name, :options, :klass

        def initialize(model, name, options)
          @model, @name, @options = model, name, options
        end 

        def build
          validate_options
          model.create_reflection(self.class.macro, name, options)
        end

        def self.build(model, name, options)
          new(model, name, options).build
        end

        private

        def validate_options
          options.assert_valid_keys(self.class.valid_options)
        end 
      end
    end
  end
end