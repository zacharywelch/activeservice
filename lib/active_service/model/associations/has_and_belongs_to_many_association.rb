module ActiveService
  module Model
    module Associations
      class HasAndBelongsToManyAssociation < Association

        def initialize(owner, opts = {})
          super owner, opts
          @opts[:path] ||= "/#{@klass.collection_path}"
        end

        # @private
        def self.attach(klass, name, opts)
          opts = {
            :class_name     => name.to_s.classify,
            :name           => name,
            :data_key       => name,
            :default        => ActiveService::Collection.new,
            :path           => nil
          }.merge(opts)
          klass.associations[macro] << opts

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, ActiveService::Model::Associations::HasAndBelongsToManyAssociation.proxy(self, #{opts.inspect}))
            end

            def #{name.to_s.singularize}_ids
              #{name}.collect(&:id)
            end
          RUBY
        end

        # @private
        def self.parse(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.nearby_class(association[:class_name])
          { association[:name] => klass.instantiate_collection(klass, data[data_key]) }
        end

        # @private
        def self.macro
          :has_and_belongs_to_many
        end

        # Initialize a new object with a foreign key to the parent
        #
        # @example
        #   class User < ActiveService::Base
        #     has_many :comments
        #   end
        #
        #   class Role < ActiveService::Base
        #   end
        #
        #   user = User.find(1)
        #   new_role = user.roles.build(:name => "admin")
        #   new_comment # => #<Comment user_id=1 body="Hello!">
        # TODO: This only merges the id of the parents, handle the case
        #       where this is more deeply nested
        def build(attributes = {})
          @klass.build(attributes.merge(:_owner_path => @owner.request_path))
        end

        # Create a new object, save it and add it to the associated collection
        #
        # @example
        #   class User < ActiveService::Base
        #     has_and_belongs_to_many :roles
        #   end
        #
        #   class Role < ActiveService::Base
        #   end
        #
        #   user = User.find(1)
        #   user.roles.create(:name => "admin")
        #   user.roles # => [#<Role id=1 name="admin">]
        def create(attributes = {})
          resource = build(attributes)
          reset if resource.save and @cached_result
          resource
        end

        # @private
        def assign_nested_attributes(attributes)
          data = attributes.is_a?(Hash) ? attributes.values : attributes
          @owner.attributes[@name] = @klass.instantiate_collection(@klass, data)
        end
      end
    end
  end
end
