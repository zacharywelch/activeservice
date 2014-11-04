module ActiveService
  module Errors
    class AssociationUnknownError < StandardError; end
    class ParserError < StandardError; end

    class PathError < StandardError
      attr_reader :missing_parameter

      def initialize(message, missing_parameter = nil)
        super message
        @missing_parameter = missing_parameter
      end
    end

    # Base class for response errors
    class ResponseError < StandardError
      attr_reader :response
      
      delegate :code, :body, :to => :response      
      
      def initialize(response)
        @response = response
      end

      def to_s
        body
      end
    end

    # 4xx Client Error
    class ClientError < ResponseError; end

    # 400 Bad Request
    class BadRequest < ClientError; end

    # 401 Unauthorized
    class UnauthorizedAccess < ClientError; end

    # 404 Not Found
    class ResourceNotFound < ClientError; end

    # 408 Timeout Error
    class TimeoutError < ResponseError; end

    # 422 Resource Invalid
    class ResourceInvalid < ClientError; end

    # 5xx Server Error
    class ServerError < ResponseError; end
  end
end