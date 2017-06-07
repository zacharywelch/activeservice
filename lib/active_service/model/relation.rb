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
      def apply_to(attributes)
        @params.merge(attributes)
      end

      # Build a new resource
      def build(attributes = {})
        @owner.build(@params.merge(attributes))
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
          request_params = params.merge(
            :_method => :get,
            :_path => @owner.build_request_path(params.merge(@owner.primary_key => id))
          )

          @owner.request(request_params) do |response|
            @owner.new_from_parsed_data(response.body) if response.success?
          end
        end

        ids.length > 1 || ids.first.kind_of?(Array) ? results : results.first
      end

      # Fetch first resource matching the specified conditions.
      #
      # If no resource is found, returns <tt>nil</tt>.
      #
      # @example
      #   @user = User.find_by(name: "Tobias Fünke", age: 42)
      #   # Called via GET "/users?name=Tobias+Fünke&age=42"
      def find_by(params)
        where(params).first
      end

      # Fetch first resource matching the specified conditions.
      #
      # In no resource is found, create one with the same attributes
      #
      # @example
      #   @user = User.find_or_create_by(email: "remi@example.com")
      #
      #   # Returns the first item in the collection if present:
      #   # Called via GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   # POST /users with `email=remi@example.com`
      def find_or_create_by(attributes)
        find_by(attributes) || create(attributes)
      end

      # Fetch first resource matching the specified conditions.
      #
      # In no resource is found, initialize one with the same attributes
      #
      # @example
      #   @user = User.find_or_initialize_by(email: "remi@example.com")
      #
      #   # Returns the first item in the collection if present:
      #   # Called via GET "/users?email=remi@example.com"
      #
      #   # If collection is empty:
      #   @user.email # => "remi@example.com"
      #   @user.new? # => true
      def find_or_initialize_by(attributes)
        find_by(attributes) || build(attributes)
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
