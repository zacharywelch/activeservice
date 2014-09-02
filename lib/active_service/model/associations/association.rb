module ActiveService
  module Model
    module Associations
      class Association
        # @private
        attr_accessor :params

        # @private
        def initialize(owner, opts = {})
          @owner = owner
          @opts = opts
          @params = {}

          @klass = @owner.class.nearby_class(@opts[:class_name])
          @name = @opts[:name]
        end

        # @private
        def self.proxy(owner, opts = {})
          AssociationProxy.new new(owner, opts)
        end

        # @private
        def self.parse_single(association, klass, data)
          data_key = association[:data_key]
          return {} unless data[data_key]

          klass = klass.nearby_class(association[:class_name])
          if data[data_key].kind_of?(klass)
            { association[:name] => data[data_key] }
          else
            { association[:name] => klass.new(data[data_key]) }
          end
        end

        # @private
        def assign_single_nested_attributes(attributes)
          if @owner.attributes[@name].blank?
            @owner.attributes[@name] = @klass.new(@klass.parse(attributes))
          else
            @owner.attributes[@name].assign_attributes(attributes)
          end
        end

        # @private
        def fetch(opts = {})
          return @opts[:default].try(:dup) if use_default?
          return @cached_result unless @params.any? || @cached_result.nil?
          return @owner.attributes[@name] unless @params.any? || @owner.attributes[@name].blank?
          
          path = build_association_path lambda { "#{@owner.request_path(@params)}#{@opts[:path]}" }
          @klass.get(path, @params).tap do |result|
            @cached_result = result unless @params.any?
          end
        end

        # @private
        def build_association_path(code)
          begin
            instance_exec(&code)
          rescue ActiveService::Errors::PathError
            return nil
          end
        end

        # Add query parameters to the HTTP request performed to fetch the data
        #
        # @example
        #   class User < ActiveService::Model
        #     has_many :comments
        #   end
        #
        #   user = User.find(1)
        #   user.comments.where(:approved => 1) # Fetched via GET "/users/1/comments?approved=1
        def where(params = {})
          return self if params.blank? && @owner.attributes[@name].blank?
          params = @klass.attribute_map.map(params, :to => :source)
          AssociationProxy.new self.clone.tap { |a| a.params = a.params.merge(params) }
        end
        alias all where

        # Add query parameters to the HTTP request performed to fetch the data
        #
        # @example
        #   class User < ActiveService::Model
        #     has_many :comments
        #   end
        #
        #   user = User.find(1)
        #   user.comments.order(:name) # Fetched via GET "/users/1/comments?sort=name_asc
        def order(params = {})
          return self if params.blank? && @owner.attributes[@name].blank?
          params = Hash[params, :asc] if params.is_a? ::Symbol
          params = { sort: @klass.attribute_map.map(params, to: :source).flatten.join('_') }
          AssociationProxy.new self.clone.tap { |a| a.params.merge! params } 
        end

        # Fetches the data specified by id
        #
        # @example
        #   class User < ActiveService::Model
        #     has_many :comments
        #   end
        #
        #   user = User.find(1)
        #   user.comments.find(3) # Fetched via GET "/users/1/comments/3
        def find(id)
          return nil if id.blank?
          path = build_association_path lambda { "#{@owner.request_path(@params)}#{@opts[:path]}/#{id}" }
          @klass.get(path, @params)
        end

        # Puts the association proxy back in its initial state, which is 
        # unloaded. Cached associations are cleared.
        def reset
          @params = {}
          @cached_result = nil
          @owner.attributes.delete(@name)
        end

        # Invokes reset and refetches association
        def reload
          reset
          fetch
        end

        private 

        def use_default?
          attribute_value = @owner.attributes[@name]
          attribute_empty = @owner.attributes.include?(@name) && attribute_value == @opts[:default]
          attribute_empty && @params.empty?
        end
      end
    end
  end
end
