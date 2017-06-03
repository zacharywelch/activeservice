module ActiveService
  module Model
    # This module handles conversion of model attributes to request parameters
    module Params
      extend ActiveSupport::Concern

      # Convert into a hash of request parameters, based on `include_root_in_json`.
      #
      # @example
      #   @user.to_params
      #   # => { :id => 1, :name => 'John Smith' }
      def to_params
        changes = modified_attributes if send_modified_attributes?
        self.class.to_params(attributes, changes)
      end

      module ClassMethods
        # @private
        def to_params(attributes, changes = {})
          params = attributes.dup.symbolize_keys
                                 .merge(embeded_params(attributes))

          if changes.present?
            params = changes.keys.each_with_object({}) do |attribute, hash|
              hash[attribute] = attributes[attribute]
            end
          end

          params = attribute_map.map(params, to: :source).symbolize_keys

          if include_root_in_json?
            if json_api_format?
              { included_root_element => [params] }
            else
              { included_root_element => params }
            end
          else
            params
          end
        end

        # @private
        def embeded_params(attributes)
          attributes = attributes.with_indifferent_access

          embed_has_one(attributes).merge(embed_has_many(attributes))
        end

        # @private
        def embed_has_one(attributes)
          associations[:has_one].select { |a| attributes.include?(a[:data_key]) }.compact.inject({}) do |hash, association|
            params = attributes[association[:data_key]].try(:to_params)
            next hash if params.nil?
            if association[:class_name].constantize.include_root_in_json?
              root = association[:class_name].constantize.root_element
              hash[association[:data_key]] = params[root]
            else
              hash[association[:data_key]] = params
            end
            hash
          end || {}
        end

        # @private
        def embed_has_many(attributes)
          associations[:has_many].select { |a| attributes.include?(a[:data_key]) }.compact.inject({}) do |hash, association|
            params = attributes[association[:data_key]].map(&:to_params)
            next hash if params.empty?
            if association[:class_name].constantize.include_root_in_json?
              root = association[:class_name].constantize.root_element
              hash[association[:data_key]] = params.map { |n| n[root] }
            else
              hash[association[:data_key]] = params
            end
            hash
          end || {}
        end
      end
    end
  end
end
