module ActiveService
  module Associations
    module Builder 
      class BelongsTo < Association
        self.valid_options += [:foreign_key]

        self.macro = :belongs_to

        def build
          validate_options
          model.create_reflection(self.class.macro, name, options).tap do |reflection|
            model.defines_belongs_to_finder_method(reflection.name, 
              reflection.klass, reflection.foreign_key)
          end
        end
      end
    end
  end
end