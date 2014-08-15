module ActiveService
  module Middleware
    class ParseJSON < Faraday::Response::Middleware
      def on_complete(env)
        env[:body] = JSON.parse(env[:body], symbolize_names: true)
      end
    end
  end
end
