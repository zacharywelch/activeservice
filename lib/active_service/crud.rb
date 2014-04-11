require 'active_service/relation'
# = CRUD
# 
# CRUD encapsulates the operations for reading and writing data to a 
# web service backend using an interface similar to ActiveRecord.
module ActiveService
  module CRUD    
    
    # Saves the model.
    #
    # If the model is new an HTTP +POST+ request is sent to the server, otherwise
    # the existing record gets updated via an HTTP +PUT+.
    #
    # By default, save always run validations. If any of them fail the action
    # is cancelled and +save+ returns +false+. Adding validations to your client 
    # models can save a round trip to the service and increase performance. 
    #
    # There's a series of callbacks associated with +save+. If any of the
    # <tt>before_*</tt> callbacks return +false+ the action is cancelled and
    # +save+ returns +false+. See ActiveRecord::Callbacks for further
    # details.
    #
    # Similar to ActiveRecord, if +save+ returns false you can check the 
    # object's errors array for any validations that failed. ActiveService will 
    # add client and server validations that fail to the same array for 
    # easy access.
    def save
      run_callbacks(:save) do 
        new? ? create : update
      end
    end

    # Deletes the model from the service backend and freezes this instance to
    # reflect that no changes should be made (since they can't be
    # persisted). Returns the frozen instance.
    #
    # The row is simply removed with an HTTP +DELETE+ statement on the
    # record's primary key, and no callbacks are executed.
    #
    # There's a series of callbacks associated with <tt>destroy</tt>. If
    # the <tt>before_destroy</tt> callback return +false+ the action is cancelled
    # and <tt>destroy</tt> returns +false+. See
    # ActiveRecord::Callbacks for further details.
    def destroy
      run_callbacks(:destroy) do
        self.class.destroy(id)
      end if persisted?
    end

    # Updates the attributes of the model from the passed-in hash and saves the
    # record. If the object is invalid, the saving will fail and false 
    # will be returned.
    def update_attributes(attributes, options = {})
      assign_attributes(attributes, options) && save
    end

    def from_json(json, include_root=include_root_in_json)
      hash = JSON.parse(json)
      self.attributes = attributes_from_json(hash)
      self
    end

    protected

      # Creates a record with values matching those of the instance attributes. 
      # Returns the object if the create was successful, otherwise it 
      # returns nil. An HTTP +POST+ request is sent to the service backend and 
      # the JSON result is used to set the model attributes.
      def create
        run_callbacks :create do
          response = Typhoeus::Request.post(self.class.base_uri, body: to_json)
          load_attributes_from_response(response)
        end
      end
      
      # Updates the associated record with values matching those of the instance 
      # attributes. Returns true if the update was successful, otherwise false.
      # An HTTP +PUT+ request is sent to the service backend and the JSON result 
      # is used to set the model attributes.
      def update
        run_callbacks :update do
          response = Typhoeus::Request.put(self.class.id_uri(id), body: to_json)
          load_attributes_from_response(response).present?
        end
      end

      # Parses the HTTP response and uses the JSON body to set the model 
      # attributes if it was successful. If a request was malformed (400) or 
      # not found (404), the errors are parsed from the response body and used 
      # to set the errors array on the model. Any other HTTP errors will raise 
      # an exception with the response body as its message
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

      # Map a json hash to the model's attributes
      def attributes_from_json(hash)
        self.class.field_map.by_target.inject({}) do |result, (target, source)|
          result[target] = hash[source]
          result
        end
      end

    module ClassMethods

      # The api endpoint for the service (e.g. http://api.com/v1/users)
      attr_accessor :base_uri

      # Class method for setting the default HTTP request headers
      # Example: self.headers  = { Authorization: "secretdecoderring" }
      attr_accessor :headers

      # Sets the parser to use when a collection is returned. The parser must be Enumerable.
      def collection_parser=(parser_instance)
        parser_instance = parser_instance.constantize if parser_instance.is_a?(String)
        @collection_parser = parser_instance
      end

      def collection_parser
        @collection_parser ||= ActiveService::Config.default_collection_parser
      end

      # Issues an HTTP +POST+ to the remote service if validations pass. 
      # The resulting object is returned whether the object was saved 
      # successfully by the remote service or not.
      #
      # The +attributes+ parameter should be a Hash of the attributes on the 
      # object being created.
      #
      # Example: User.create(name: 'foo', email: 'foo@bar.com')
      def create(attributes = nil)
        new(attributes).tap { |object| object.save }
      end

      # Issues an HTTP +DELETE+ to the remote service if validations pass. 
      # Returns true if the request was successful, otherwise false.
      #
      # Example: User.destroy(166) #=> true
      def destroy(id)
        response = Typhoeus::Request.delete(id_uri(id))
        response.success?
      end

      # Core method for finding resources. Used similarly to Active Record's 
      # +find+ method.
      #
      # ==== Arguments
      # The first argument is considered to be the scope of the query. That is, 
      # how many resources are returned from the request. It can be one of the 
      # following.
      #
      # * <tt>:first</tt> - Returns the first resource found.
      # * <tt>:last</tt> - Returns the last resource found.
      # * <tt>:all</tt> - Returns every resource that matches the request.
      #
      # ==== Options
      #
      # * <tt>:from</tt> - Sets the path or custom method that resources will be 
      #                    fetched from.
      # * <tt>:params</tt> - Sets query and \prefix (nested URL) parameters.
      #
      # ==== Examples
      #   Person.find(1)
      #   # => GET /people/1.json
      #
      #   Person.find(:all)
      #   # => GET /people.json
      #
      #   Person.find(:all, :params => { :title => "CEO" })
      #   # => GET /people.json?title=CEO
      #
      #   Person.find(:first, :from => "http://site.com/people/getpeople")
      #   # => GET /people/getpeople.json
      #
      #   Person.find(:last, :from => "http://site.com/people/getpeople")
      #   # => GET /people/getpeople.json
      #
      #   Person.find(:all, :from => "http://site.com/people/getpeople")
      #   # => GET /people/getpeople.json
      #
      #   Person.find(:all, :from => "http://site.com/people/getpeople", 
      #                 :params => { :name => 'foo' })
      #   # => GET /people/getpeople.json?name=foo
      #
      # Find returns nil when no data is returned.
      #
      #   Person.find(1)
      #   # => nil
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

      # This is an alias for find(:all). You can pass in all the same
      # arguments to this method as you can to <tt>find(:all)</tt>
      def all(*args)
        find(:all, *args)
      end

      # This is an alias for find(:first). You can pass in all the same
      # arguments to this method as you can to <tt>find(:first)</tt>      
      def first(*args)
        find(:first, *args)
      end

      # This is an alias for find(:last). You can pass in all the same
      # arguments to this method as you can to <tt>find(:last)</tt>      
      def last(*args)
        find(:last, *args)
      end

      # This is a shortcut for finding the total count of objects. Be advised 
      # it will query all the objects in memory and return a count. A more 
      # efficient method would be to create a +count+ service method that 
      # returns count in the response body instead of all objects.
      def count
        find(:all).count
      end

      # This is an alias for find(:all) which passes a params option.
      # params are mapped to their source columns before calling the service
      def where(clauses = {})
        unless clauses.is_a? Hash
          raise ArgumentError, "expected a clauses Hash, got #{clauses.inspect}"
        end
        clauses = field_map.map(clauses, :by => :target)
        Relation.new(self).where(clauses)
        # find(:all, params: clauses)
      end

      # Helper method for calculating a URI based on the object's id
      def id_uri(id)
        "#{base_uri}/#{id}"
      end

      private

        def default_options
          { headers: headers }
        end

        def instantiate_record(record)
          new.from_json(record.to_json)
        end

        def instantiate_collection(collection)
          collection_parser.new(collection).tap do |parser|
            parser.resource_class = self
          end.collect! { |record| instantiate_record(record) }
        end

        # Find a single resource from the default URL
        def find_single(id, options)
          options = default_options.merge(options)
          response = Typhoeus::Request.get(id_uri(id), options)
          if response.success?
            instantiate_record(JSON.parse(response.body))
          elsif response.code == 404
            nil
          else
            raise response.body
          end
        end

        # find every resource
        def find_every(options)
          from = options.delete(:from) || base_uri
          options = default_options.merge(options)
          response = Typhoeus::Request.get(from, options)
          if response.success?
            instantiate_collection(JSON.parse(response.body))
          else
            raise response.body
          end
        end
    end
  end
end
