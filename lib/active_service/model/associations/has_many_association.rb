module ActiveService
  module Model
    module Associations
      class HasManyAssociation < Association

        def initialize(owner, opts = {})
          klass = owner.class.nearby_class(opts[:class_name])
          super owner, opts.merge(path: "/#{klass.collection_path}")
        end

        # @private
        def self.attach(klass, name, opts)
          opts = {
            :class_name     => name.to_s.classify,
            :name           => name,
            :data_key       => name,
            :default        => ActiveService::Collection.new,
            :path           => "/#{name}",
            :inverse_of => nil
          }.merge(opts)
          klass.associations[:has_many] << opts

          klass.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{name}
              cached_name = :"@association_#{name}"

              cached_data = (instance_variable_defined?(cached_name) && instance_variable_get(cached_name))
              cached_data || instance_variable_set(cached_name, ActiveService::Model::Associations::HasManyAssociation.proxy(self, #{opts.inspect}))
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

        # Initialize a new object with a foreign key to the parent
        #
        # @example
        #   class User < ActiveService::Base
        #     has_many :comments
        #   end
        #
        #   class Comment < ActiveService::Base
        #   end
        #
        #   user = User.find(1)
        #   new_comment = user.comments.build(:body => "Hello!")
        #   new_comment # => #<Comment user_id=1 body="Hello!">
        # TODO: This only merges the id of the parents, handle the case
        #       where this is more deeply nested
        def build(attributes = {})
          @klass.build(attributes.merge(:"#{@owner.singularized_resource_name}_id" => @owner.id))
        end

        # Create a new object, save it and add it to the associated collection
        #
        # @example
        #   class User < ActiveService::Base
        #     has_many :comments
        #   end
        #
        #   class Comment < ActiveService::Base
        #   end
        #
        #   user = User.find(1)
        #   user.comments.create(:body => "Hello!")
        #   user.comments # => [#<Comment id=2 user_id=1 body="Hello!">]
        def create(attributes = {})
          resource = build(attributes)

          if resource.save
            @owner.attributes[@name] ||= ActiveService::Collection.new
            @owner.attributes[@name] << resource
          end

          resource
        end

        # @private
        def fetch
          super.tap do |o|
            writer = "#{@opts[:inverse_of] || @owner.singularized_resource_name}="
            o.each { |entry| entry.send(writer, @owner) }
          end
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
