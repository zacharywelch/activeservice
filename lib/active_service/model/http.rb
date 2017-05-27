module ActiveService
  module Model
    # This module interacts with ActiveService::API to fetch HTTP data
    module HTTP
      extend ActiveSupport::Concern
      METHODS = [:get, :post, :put, :patch, :delete]

      # For each HTTP method, define these class methods:
      #
      # - <method>(path, params)
      # - <method>_raw(path, params, &block)
      # - <method>_collection(path, params, &block)
      # - <method>_resource(path, params, &block)
      # - custom_<method>(*paths)
      #
      # @example
      #   class User < ActiveService::Base
      #     custom_get :active
      #   end
      #
      #   User.get(:popular) # GET "/users/popular"
      #   User.active # GET "/users/active"
      module ClassMethods
        
        # Change which API the model will use to make its HTTP requests
        #
        # @example
        #   secondary_api = ActiveService::API.new :url => "https://api.example" do |connection|
        #     connection.use Faraday::Request::UrlEncoded
        #   end
        #
        #   class User < ActiveService::Base
        #     use_api secondary_api
        #   end
        def use_api(value = nil)
          @use_api ||= begin
            superclass.use_api if superclass.respond_to?(:use_api) 
          end || ActiveService::API.default_api

          unless value
            return (@use_api.respond_to? :call) ? @use_api.call : @use_api
          end

          @use_api = value
        end
        
        alias api use_api
        alias uses_api use_api

        # Main request wrapper around ActiveService::API. Used to make custom 
        # requests to the API.
        #
        # @private
        def request(params = {})
          response = api.request(params)

          if block_given?
            yield response
          else
            response
          end
        end

        def reading_option
          @reading_option ||= {}
        end

        METHODS.each do |method|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(path, params={})
              option_to_read = reading_option[{ method: '#{method}', path: path }]
              path = build_request_path_from_string_or_symbol(path, params)
              params = to_params(params) unless #{method.to_sym.inspect} == :get
              send(:'#{method}_raw', path, params) do |response|
                parsed_data = response.body
                if parsed_data.is_a?(Array) || active_model_serializers_format? || json_api_format? || option_to_read == :collection
                  new_collection(parsed_data)
                else
                  new(parse(parsed_data))
                end
              end
            end

            def #{method}_raw(path, params={}, &block)
              path = build_request_path_from_string_or_symbol(path, params)
              request(params.merge(:_method => #{method.to_sym.inspect}, :_path => path), &block)
            end

            def #{method}_collection(path, params={})
              path = build_request_path_from_string_or_symbol(path, params)
              send(:'#{method}_raw', build_request_path_from_string_or_symbol(path, params), params) do |response|
                new_collection(response.body)
              end
            end

            def #{method}_resource(path, params={})
              path = build_request_path_from_string_or_symbol(path, params)
              send(:"#{method}_raw", path, params) do |response|
                new(parse(response.body))
              end
            end

            def custom_#{method}(*paths, **options)
              raise ArgumentError.new(':on option expects a value of :collection or :member') unless [:collection, :member].include?(options[:on])
              metaclass = (class << self; self; end)
              opts = paths.last.is_a?(Hash) ? paths.pop : Hash.new

              paths.each do |path|
                reading_option[{ method: '#{method}', path: path }] = options[:on]
                metaclass.send(:define_method, path) do |*params|
                  params = params.first || Hash.new
                  send(#{method.to_sym.inspect}, path, params)
                end
              end
            end
          RUBY
        end
      end
    end
  end
end
