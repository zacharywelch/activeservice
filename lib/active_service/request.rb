require 'active_support/concern'

module ActiveService
  module Request
    extend ActiveSupport::Concern

    module ClassMethods
      
      def get(path, options = {})
        response = Typhoeus::Request.get(path, default_options.merge(options))
        if response.success?
          JSON.parse(response.body)
        else
          raise response.body
        end
      end

      def post(path, options = {})
        response = Typhoeus::Request.post(path, default_options.merge(options))
        if response.success?
          JSON.parse(response.body)
        else
          raise response.body
        end
      end

      def put(path, options = {})
        response = Typhoeus::Request.put(path, default_options.merge(options))
        if response.success?
          JSON.parse(response.body)
        else
          raise response.body
        end
      end

      def delete(path, options = {})
        response = Typhoeus::Request.delete(path, default_options.merge(options))
        if response.success?
          JSON.parse(response.body)
        else
          raise response.body
        end
      end
    end
  end
end