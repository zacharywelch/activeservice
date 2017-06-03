module ActiveService
  module Middleware
    class ParseJSON < Faraday::Response::Middleware
      def on_complete(env)
        begin
          env[:body] = parse_json(env[:body])
        rescue JSON::ParserError
          raise ActiveService::Errors::ParserError
        end
      end

      private

      # @private
      def parse_json(body = nil)
        body = '{}' if body.blank?
        message = "Response from the API must behave like a Hash or an Array (last JSON response was #{body.inspect})"

        json = begin
          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError
          raise ActiveService::Errors::ParserError, message
        end

        raise ActiveService::Errors::ParserError, message unless json.is_a?(Hash) or json.is_a?(Array)

        json
      end
    end
  end
end
