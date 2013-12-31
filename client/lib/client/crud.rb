require 'typhoeus'

module Persistence
  module CRUD    
    
    def save
      run_callbacks(:save) do 
        new? ? create : update
      end
    end

    def destroy
      run_callbacks(:destroy) do
        self.class.destroy(id)
      end if persisted?
    end

    def update_attributes(attributes, options = {})
      assign_attributes(attributes, options) && save
    end

    protected

      def create
        run_callbacks :create do
          response = Typhoeus::Request.post(self.class.base_uri, body: to_json)
          load_attributes_from_response(response)
        end
      end
      
      def update
        run_callbacks :update do
          response = Typhoeus::Request.put(self.class.id_uri(id), body: to_json)
          load_attributes_from_response(response).present?
        end
      end

      def load_attributes_from_response(response)
        if response.success?
          from_json(response.body)        
        elsif [400, 404].include? response.code  
          msgs = JSON.parse(response.body)
          msgs.each do |attr, attr_errors|
            attr_errors.each { |error| errors.add(attr, error) }
          end
          nil
        else
          raise response.body
        end
      end

    module ClassMethods

      attr_accessor :base_uri, :headers

      def create(attributes = nil)
        new(attributes).tap { |object| object.save }
      end

      def destroy(id)
        response = Typhoeus::Request.delete(id_uri(id))
        response.success?
      end

      def find(*args)
        scope   = args.slice!(0)
        options = args.slice!(0) || {}

        case scope
          when :all   then find_every(options)
          when :first then find_every(options).first
          when :last  then find_every(options).last
          else             find_single(scope, options)
        end
      end

      def all(*args)
        find(:all, *args)
      end

      def first(*args)
        find(:first, *args)
      end

      def last(*args)
        find(:last, *args)
      end

      def count
        find(:all).count
      end

      def where(clauses = {})
        unless clauses.is_a? Hash
          raise ArgumentError, "expected a clauses Hash, got #{clauses.inspect}"
        end
        find(:all, params: clauses)
      end

      def id_uri(id)
        "#{base_uri}/#{id}"
      end

      private

        def default_options
          { headers: headers }
        end

        def find_single(id, options)
          response = Typhoeus::Request.get(id_uri(id))
          if response.success?
            new.from_json(response.body)
          elsif response.code == 404
            nil
          else
            raise response.body
          end
        end

        def find_every(options)
          from = options.delete(:from) || base_uri
          options = default_options.merge(options)
          response = Typhoeus::Request.get(from, options)
          if response.success?
            JSON.parse(response.body).map { |hash| new(hash) }
          else
            raise response.body
          end
        end
    end
  end
end
