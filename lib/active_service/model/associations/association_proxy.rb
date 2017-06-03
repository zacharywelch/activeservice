module ActiveService
  module Model
    module Associations
      class AssociationProxy < (ActiveSupport.const_defined?('ProxyObject') ? ActiveSupport::ProxyObject : ActiveSupport::BasicObject)

        # @private
        def self.install_proxy_methods(target, *names)
          names.each do |name|
            module_eval <<-RUBY, __FILE__, __LINE__ + 1
              def #{name}(*args, &block)
                #{target}.send(#{name.inspect}, *args, &block)
              end
            RUBY
          end
        end

        install_proxy_methods :association,
          :build, :create, :destroy, :where, :order, :find, :all,
          :assign_nested_attributes, :reset, :reload

        # @private
        def initialize(association)
          @association = association
        end

        def association
          @association
        end

        # @private
        def method_missing(name, *args, &block)
          if :object_id == name # avoid redefining object_id
            return association.fetch.object_id
          end

          # create a proxy to the target object's method
          metaclass = (class << self; self; end)
          metaclass.install_proxy_methods target_for(name), name

          # resend message to fetched object
          __send__(name, *args, &block)
        end

        private

        def target_for(method)
          scope = association.klass.respond_to?(method) && association.klass.singleton_methods(false).include?(method)
          scope ? 'association.scoped' : 'association.fetch'
        end

      end
    end
  end
end
