require 'active_service/model/params/symbolizer'

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
        self.class.to_params(symbolize_attributes)
      end

      # @private
      def symbolize_attributes
        Symbolizer.new(attributes).symbolize
      end

      module ClassMethods
        # @private
        def to_params(attributes)
          params = attribute_map.map(attributes, to: :source).symbolize_keys

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
      end
    end
  end
end
