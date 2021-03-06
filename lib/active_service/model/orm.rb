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
      rescue ActiveService::Errors::BadRequest, ActiveService::Errors::ResourceInvalid => e
        assign_errors e.response.body
        nil
      end

      # Similar to save(), except that ResourceInvalid is raised if the save fails
      def save!
        if !self.save
          raise ActiveService::Errors::ResourceInvalid.new(self)
        end
        self
      end

      # Update a resource and return it
      #
      # @example
      #   @user = User.find(1)
      #   @user.update_attributes(:name => "Tobias Fünke")
      #   # Called via PUT "/users/1"
      def update_attributes(attributes)
        assign_attributes(attributes) && save
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
            data = response.body
            assign_attributes(self.class.parse(data)) if data.any?
            @destroyed = true
          end
        end if persisted?
        self
      end

      # Initializes +attribute+ to zero if +nil+ and adds the value passed as
      # +by+ (default is 1). The increment is performed directly on the
      # underlying attribute, no setter is invoked. Only makes sense for
      # number-based attributes. Returns +self+.
      def increment(attribute, by = 1)
        attributes[attribute] ||= 0
        attributes[attribute] += by
        self
      end

      # Wrapper around #increment that saves the resource. Saving is subjected
      # to validation checks. Returns +self+.
      def increment!(attribute, by = 1)
        increment(attribute, by) && save
        self
      end

      # Initializes +attribute+ to zero if +nil+ and subtracts the value passed as
      # +by+ (default is 1). The decrement is performed directly on the
      # underlying attribute, no setter is invoked. Only makes sense for
      # number-based attributes. Returns +self+.
      def decrement(attribute, by = 1)
        increment(attribute, -by)
      end

      # Wrapper around #decrement that saves the resource. Saving is subjected
      # to validation checks. Returns +self+.
      def decrement!(attribute, by = 1)
        increment!(attribute, -by)
      end

      # Assigns to +attribute+ the boolean opposite of <tt>attribute?</tt>. So
      # if the predicate returns +true+ the attribute will become +false+. This
      # method toggles directly the underlying value without calling any setter.
      # Returns +self+.
      #
      # @example
      #   user = User.first
      #   user.admin? # => false
      #   user.toggle(:admin)
      #   user.admin? # => true
      def toggle(attribute)
        self[attribute] = !public_send("#{attribute}?")
        self
      end

      # Wrapper around #toggle that saves the resource. Saving is subjected to
      # validation checks. Returns +true+ if the record could be saved.
      def toggle!(attribute)
        toggle(attribute) && save
      end

      # Refetches the resource
      #
      # This method finds the resource by its primary key (which could be
      # assigned manually) and modifies the object in-place.
      #
      # @example
      #   class User < ActiveService::Base
      #     attribute :name
      #   end
      #
      #   user = User.find(1)
      #   # => #<User(users/1) id=1 name="Tobias Fünke">
      #   user.name = "Oops"
      #   user.reload # Fetched again via GET "/users/1"
      #   # => #<User(users/1) id=1 name="Tobias Fünke">
      def reload(options = nil)
        fresh_object = self.class.find(id)
        assign_attributes(fresh_object.attributes)
        self
      end

      protected

      # Creates a record with values matching those of the instance attributes.
      # Returns the object if the create was successful, otherwise it
      # returns nil. An HTTP +POST+ request is sent to the service backend and
      # the JSON result is used to set the model attributes.
      def create
        run_callbacks :create do
          method = self.class.method_for(:create)
          path = request_path(:_owner_path => @owner_path)
          self.class.request(to_params.merge(:_method => method, :_path => path)) do |response|
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
          method = self.class.method_for(:update)
          path = request_path(:_owner_path => @owner_path)
          self.class.request(to_params.merge(:_method => method, :_path => path)) do |response|
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
        data = response.body
        assign_attributes(self.class.parse(data)) unless data.empty?
        changes_applied
        self
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
        [:all, :where, :order, :create, :build, :find, :find_by,
         :find_or_create_by, :find_or_initialize_by, :first, :last, :limit,
         :first_or_create, :first_or_initialize].each do |method|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{method}(*params)
              scoped.send(#{method.to_sym.inspect}, *params)
            end
          RUBY
        end

        # Save an existing resource and return it
        #
        # @example
        #   @user = User.save_existing(1, { fullname: "Tobias Fünke" })
        #   # Called via PUT "/users/1"
        def save_existing(id, params)
          resource = new(params.merge(primary_key => id))
          resource.save
          resource
        end

        # Build a new resource with the given attributes.
        # If the request_new_object_on_build flag is set, the new object is requested via API.
        def build(attributes = {})
          params = attributes
          return new(params) unless request_new_object_on_build?

          path = build_request_path(params.merge(primary_key => 'new'))

          request(params.merge(:_method => :get, :_path => path)) do |response|
            new_from_parsed_data(response.body) if response.success?
          end
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
            new(parse(response.body).merge(:_destroyed => true))
          end
        end

        # Return or change the HTTP method used to create or update records
        #
        # @param [Symbol, String] action The behavior in question (`:create` or `:update`)
        # @param [Symbol, String] method The HTTP method to use (`'PUT'`, `:post`, etc.)
        def method_for(action = nil, method = nil)
          @method_for ||= (superclass.respond_to?(:method_for) ? superclass.method_for : {})
          return @method_for if action.nil?

          action = action.to_s.downcase.to_sym

          return @method_for[action] if method.nil?
          @method_for[action] = method.to_s.downcase.to_sym
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

