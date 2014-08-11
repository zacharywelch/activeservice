module ActiveService
  module Errors
    class PathError < StandardError
      attr_reader :missing_parameter

      def initialize(message, missing_parameter = nil)
        super message
        @missing_parameter = missing_parameter
      end
    end

    # Base class for response errors
    class ResponseError < StandardError
      attr_reader :code
      
      def initialize(code, message = nil)
        super message
        @code = code
      end
    end

    # 4xx Client Error
    class ClientError < ResponseError; end

    # 400 Bad Request
    class BadRequest < ClientError
      def initialize
        super 400
      end
    end

    # 401 Unauthorized
    class UnauthorizedAccess < ClientError
      def initialize
        super 401
      end
    end

    # 404 Not Found
    class ResourceNotFound < ClientError
      def initialize
        super 404
      end
    end

    # 408 Timeout Error
    class TimeoutError < ResponseError
      def initialize
        super 408
      end
    end

    # 422 Resource Invalid
    class ResourceInvalid < ClientError
      def initialize
        super 422
      end
    end

    # 5xx Server Error
    class ServerError < ResponseError
      def initialize
        super 500
      end
    end    
  end
end