module ActiveService
  module Model
    class Relation
      # @private
      attr_accessor :params

      # @private
      def initialize(owner)
        @owner = owner
        @params = {}
      end

      # @private
      def connection
        @owner.api.connection
      end

      # @private
      def apply_to(attributes)
        @params.merge(attributes)
      end

      # Build a new resource
      def build(attributes = {})
        @owner.build(@params.merge(attributes))
      end

      def includes(id, associations = [])
        data = build_request_paths(id, associations)
        connection.in_parallel do
          data[:instance_response] = connection.get(data[:instance_path])
          data[:associations].each do |assocation|
            assocation[:response] = connection.get(assocation[:path])
          end
        end
        data[:instance_response] = handle_response(data[:instance_response])
        @owner.new(attributes_with_associations(data))
      end

      # @private
      def build_request_paths(id, associations)
        data = {}
        data[:instance_path] = @owner.build_request_path(id: id)
        data[:associations] = []
        associations.each do |a|
          data[:associations] << build_assocation_hash(data[:instance_path], a)
        end
        data
      end

      # @private
      def build_assocation_hash(instance_path, association)
        hash = {}
        hash[:name] = association
        hash[:class] = @owner.associations[:has_many].detect {
          |a| a[:name] == association }[:class_name].constantize
        hash[:path] = "#{instance_path}/#{hash[:class].build_request_path}"
        hash
      end      

      # @private
      def attributes_with_associations(data)
        attributes = @owner.new_from_parsed_data(data[:instance_response].body).attributes
        data[:associations].each do |a|
          merge_attributes!(attributes, a) unless unsuccessful?(a[:response].body)
        end
        attributes
      end

      # @private
      def merge_attributes!(attributes, association)
        collection = @owner.instantiate_collection(association[:class], association[:response].body)
        attributes.merge!(association[:name] => collection)
      end

      # @private
      def unsuccessful?(body)
        (body.is_a? Hash and body[:Errors]) or body.nil?
      end

      # @private
      def handle_response(response)
        case response.status
          when 200, 201
            response
          when 400
            raise ActiveService::Errors::BadRequest.new(response)
          when 401
            raise ActiveService::Errors::UnauthorizedAccess.new(response)
          when 404
            raise ActiveService::Errors::ResourceNotFound.new(response)
          when 422
            raise ActiveService::Errors::ResourceInvalid.new(response)
          when 401..499
            raise ActiveService::Errors::ClientError.new(response)
          when 500..599
            raise ActiveService::Errors::ServerError.new(response)
          else
            raise response.body
        end
      end

      # Add a query string parameter
      #
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.where(:approved => 1)
      #   # Fetched via GET "/users?approved=1"
      def where(params = {})
        return self if params.blank? && !@_fetch.nil?
        params = @owner.attribute_map.map(params, :to => :source)
        self.clone.tap do |r|
          r.params = r.params.merge(params)
          r.clear_fetch_cache!
        end
      end
      alias all where

      # Specifies a limit for the number of records to retrieve.
      #
      #   User.limit(10) # generated HTTP has '?limit=10'
      #
      #   User.limit(10).limit(20) # generated HTTP has '?limit=20'
      def limit(value)
        return self if value.nil? && !@_fetch.nil?
        where(limit: value)
      end

      # Fetch the first or last record
      # @note
      #   This is not the most efficient way of returning the first or last
      #   resource because a fetch is required but it's provided for convenience
      delegate :first, :last, :to => :fetch

      # Add a query string parameter for sorting
      #
      # @example
      #   @users = User.all
      #   # Fetched via GET "/users"
      #
      # @example
      #   @users = User.order(:name)
      #   # Fetched via GET "/users?sort=name_asc"
      #
      # @example
      #   @users = User.order(:name => :desc)
      #   # Fetched via GET "/users?sort=name_desc"
      #
      # @example
      #   @users = User.order(:name => :asc)
      #   # Fetched via GET "/users?sort=name_asc"
      def order(params = {})
        return self if params.blank? && !@_fetch.nil?
        params = Hash[params, :asc] if params.is_a?(::Symbol) || params.is_a?(::String)
        params = @owner.attribute_map.map(params.symbolize_keys, :to => :source)
        self.clone.tap do |r|
          r.params.merge!(:sort => params.flatten.join('_'))
          r.clear_fetch_cache!
        end
      end

      # @note hack until ProxyObject is available
      undef_method :inspect, :equal?, :eql?, :==

      # Bubble all methods to the fetched collection
      #
      # @private
      def method_missing(method, *args, &blk)
        fetch.send(method, *args, &blk)
      end

      # @private
      def respond_to?(method, *args)
        super || fetch.respond_to?(method, *args)
      end

      # @private
      def nil?
        fetch.nil?
      end

      # @private
      def kind_of?(thing)
        fetch.kind_of?(thing)
      end

      # Fetch a collection of resources
      #
      # @private
      def fetch
        @_fetch ||= begin
          path = @owner.build_request_path(@params)
          @owner.request(@params.merge(:_method => :get, :_path => path)) do |response|
            @owner.new_collection(response.body)
          end
        end
      end

      # Fetch specific resource(s) by their ID
      #
      # @example
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      #
      # @example
      #   @users = User.find([1, 2])
      #   # Fetched via GET "/users/1" and GET "/users/2"
      def find(*ids)
        params = @params.merge(ids.last.is_a?(Hash) ? ids.pop : {})
        ids = Array(params[@owner.primary_key]) if params.key?(@owner.primary_key)
        results = ids.flatten.compact.uniq.map do |id|
          resource = nil
          request_params = params.merge(
            :_method => :get,
            :_path => @owner.build_request_path(params.merge(@owner.primary_key => id))
          )

          @owner.request(request_params) do |response|
            if response.success?
              resource = @owner.new_from_parsed_data(response.body)
            else
              return nil
            end
          end

          resource
        end

        ids.length > 1 || ids.first.kind_of?(Array) ? results : results.first
      end

      # Create a resource and return it
      #
      # @example
      #   @user = User.create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&fullname=Tobias+Fünke`
      #
      # @example
      #   @user = User.where(:email => "tobias@bluth.com").create(:fullname => "Tobias Fünke")
      #   # Called via POST "/users/1" with `&email=tobias@bluth.com&fullname=Tobias+Fünke`
      def create(attributes = {})
        attributes ||= {}
        resource = @owner.new(@params.merge(attributes))
        resource.save

        resource
      end

      # Fetch a resource and create it if it's not found
      #
      # @example
      #   @user = User.where(:email => "foo@bar.com").first_or_create
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=foo@bar.com"
      #
      #   # If collection is empty:
      #   # POST /users with `email=foo@bar.com`
      def first_or_create(attributes = {})
        first || create(attributes)
      end

      # Fetch a resource and build it if it's not found
      #
      # @example
      #   @user = User.where(:email => "foo@bar.com").first_or_initialize
      #
      #   # Returns the first item of the collection if present:
      #   # GET "/users?email=foo@bar.com"
      #
      #   # If collection is empty:
      #   @user.email # => "foo@bar.com"
      #   @user.new? # => true
      def first_or_initialize(attributes = {})
        first || build(attributes)
      end

      # @private
      def clear_fetch_cache!
        instance_variable_set(:@_fetch, nil)
      end
    end
  end
end
