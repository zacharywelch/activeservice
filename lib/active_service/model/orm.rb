module ActiveService
  module Model
    # This module adds ORM-like capabilities to the model
    module ORM
      extend ActiveSupport::Concern

      # Return `true` if a resource was not saved yet
      def new?
        id.nil?
      end

      # Return `true` if a resource is not `#new?`
      def persisted?
        !new?
      end

      # Return whether the object has been destroyed
      def destroyed?
        @destroyed == true
      end

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
      #
      # @example Save a resource after fetching it
      #   @user = User.find(1)
      #   # Fetched via GET "/users/1"
      #   @user.fullname = "Tobias Fünke"
      #   @user.save
      #   # Called via PUT "/users/1"
      #
      # @example Save a new resource by creating it
      #   @user = User.new({ :fullname => "Tobias Fünke" })
      #   @user.save
      #   # Called via POST "/users"
      def save
        run_callbacks :save do
          new? ? create : update
        end
      end

      # Similar to save(), except that ResourceInvalid is raised if the save fails
      def save!
        if !self.save
          raise ActiveService::Errors::ResourceInvalid
        end 
        self
      end

      # Update a resource and return it
      #
      # @example
      #   @user = User.find(1)
      #   @user.update_attributes(:name => "Tobias Fünke")
      #   # Called via PUT "/users/1"
      def update_attributes(attributes, options = {})
        assign_attributes(attributes, options) && save
      end

      # Destroy a resource
      #
      # @example
      #   @user = User.find(1)
      #   @user.destroy
      #   # Called via DELETE "/users/1"
      def destroy
        run_callbacks :destroy do
          self.class.request(:_method => :delete, :_path => request_path) do |response|
            data = JSON.parse(response.body)
            assign_attributes(self.class.parse(data)) if data.any?
            @destroyed = true
          end
        end if persisted?
        self
      end

      protected

      # Creates a record with values matching those of the instance attributes. 
      # Returns the object if the create was successful, otherwise it 
      # returns nil. An HTTP +POST+ request is sent to the service backend and 
      # the JSON result is used to set the model attributes.
      def create
        run_callbacks :create do
          self.class.post_raw(request_path, to_params) do |response|
            load_attributes_from_response(response)
          end
        end
      end

      # Updates the associated record with values matching those of the instance 
      # attributes. Returns true if the update was successful, otherwise false.
      # An HTTP +PUT+ request is sent to the service backend and the JSON result 
      # is used to set the model attributes.
      def update
        run_callbacks :update do
          self.class.put_raw(request_path, to_params) do |response|
            load_attributes_from_response(response)
          end
        end
      end      

      # Parses the HTTP response and uses the JSON body to set the model 
      # attributes if it was successful. If a request was malformed (400) or 
      # not found (404), the errors are parsed from the response body and used 
      # to set the errors array on the model. Any other HTTP errors will raise 
      # an exception with the response body as its message
      def load_attributes_from_response(response)
        data = JSON.parse(response.body)
        self.class.handle_response(response)
        assign_attributes(self.class.parse(data)) unless data.empty?
        self
      rescue ActiveService::Errors::BadRequest, ActiveService::Errors::ResourceInvalid
        assign_errors data
        nil  
      end

      # Assign resource errors to ActiveModel errors array 
      def assign_errors(items)
        items.each do |attr, attr_errors|
          attr_errors.each { |error| errors.add(attr, error) }
        end
      end

      module ClassMethods
        # Create a new chainable scope
        #
        # @example
        #   class User < ActiveService::Base
        #
        #     scope :admins, lambda { where(:admin => 1) }
        #     scope :page, lambda { |page| where(:page => page) }
        #   enc
        #
        #   User.admins # Called via GET "/users?admin=1"
        #   User.page(2).all # Called via GET "/users?page=2"
        def scope(name, code)
          # Add the scope method to the class
          (class << self; self end).send(:define_method, name) do |*args|
            instance_exec(*args, &code)
          end

          # Add the scope method to the Relation class
          Relation.instance_eval do
            define_method(name) { |*args| instance_exec(*args, &code) }
          end
        end        

        # @private
        def scoped
          @_default_scope || blank_relation
        end

        # Define the default scope for the model
        #
        # @example
        #   class User < ActiveService::Base
        #
        #     default_scope lambda { where(:admin => 1) }
        #   enc
        #
        #   User.all # Called via GET "/users?admin=1"
        #   User.new.admin # => 1
        def default_scope(block=nil)
          @_default_scope ||= (!respond_to?(:default_scope) && superclass.respond_to?(:default_scope)) ? superclass.default_scope : scoped
          @_default_scope = @_default_scope.instance_exec(&block) unless block.nil?
          @_default_scope
        end

        # Delegate the following methods to `scoped`
        [:all, :where, :create, :build, :find, :first_or_create, :first_or_initialize].each do |method|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(*params)
              scoped.send(#{method.to_sym.inspect}, *params)
            end
          RUBY
        end   

        # Build a new resource with the given attributes.
        # If the request_new_object_on_build flag is set, the new object is requested via API.
        def build(attributes = {})
          params = attributes
          return self.new(params) unless self.request_new_object_on_build?

          path = self.build_request_path(params.merge(self.primary_key => 'new'))

          resource = nil
          self.request(params.merge(:_method => :get, :_path => path)) do |response|
            if response.success?
              resource = self.new_from_parsed_data(JSON.parse(response.body))
            end
          end
          resource
        end

        # Destroy an existing resource
        # Returns true if the request was successful, otherwise false.
        #
        # @example
        #   User.destroy(1)
        #   # Called via DELETE "/users/1"
        def destroy(id, params = {})          
          path = build_request_path(params.merge(primary_key => id))
          request(params.merge(:_method => :delete, :_path => path)) do |response|
            new(parse(JSON.parse(response.body)).merge(:_destroyed => true))
          end
        end

        private
        # @private
        def blank_relation
          @blank_relation ||= Relation.new(self)
        end        
      end
    end
  end
end

