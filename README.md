# ActiveService

Active Service is an ORM that maps REST resources to Ruby objects using an ActiveRecord-like interface. 

## Installation

```ruby
gem install 'active_service'
```

In your Gemfile add
```ruby
gem 'active_service'
```

## Getting Started

Setup an API for your Active Service models to use. For Rails this would go in a service initalizer like `config/initializers/active_service.rb`

```ruby
ActiveService::API.setup :url => "http://api.example.com" do |c|
  # Request
  c.use Faraday::Request::UrlEncoded
  # Response
  c.use ActiveService::Middleware::DefaultParseJSON
  # Adapter
  c.use Faraday::Adapter::NetHttp
end
```

Creating your Active Service models is simple. Inherit from `ActiveService::Base` and define your attributes.

```ruby
class User < ActiveService::Base
  attribute :name
end
```

That's it! Now you can communicate with the API using Active Record syntax.

```ruby
User.all
# => GET http://api.example.com/users

User.find(1)
# => GET http://api.example.com/users/1

user = User.create(name: 'bar')
# => POST http://api.example.com/users { "name": "bar" }

user = User.find(1)
user.name = 'bar'
user.save
# => PUT http://api.example.com/users/1 { "id": 1, "name": "bar" }
```

## CRUD: Reading and Writing Data

Active Record objects are mapped to a database via SQL `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements. With Active Service, objects are mapped to a resource via HTTP `GET`, `POST`, `PUT` and `DELETE` requests.

### Create

Creating resources with Active Service is similar to Active Record.

```ruby
user = User.create(name: "foo", email: "foo@bar.com")
# => POST /users { "name": "foo", "email": "foo@bar.com" }

user = User.new
user.name = "foo"
user.email = "foo@bar.com"
user.save
# => POST /users { "name": "foo", "email": "foo@bar.com" }
```

### Read

Active Service provides a rich API for accessing resources. A lot of the syntatic sugar you've come to love with Active Record is available in Active Service.

```ruby
users = User.all
# => GET /users

user = User.find(1)
# => GET /users/1

user = User.where(name: 'foo')
# => GET /users?name=foo

user = User.where(name: 'foo', age: 30).order(:name => :desc)
# => GET /users?name=foo&age=30&sort=name_desc

user = User.where(name: 'foo').first_or_initialize
# => GET /users?name=foo
# If collection is empty
user.name # => "foo"
user.new? # => true
```

### Update

Once an Active Service object has been retrieved, its attributes can be modified and sent back to the API using `save` or `update_attributes`. 

```ruby
user = User.find(1)
user.id # => 1
user.name = "new name"
user.save
# => PUT /users/1 { "id": 1, "name": "new name" }

user.update_attributes(name: "new new name")
# => PUT /users/1 { "id": 1, "name": "new new name" }
```

### Delete

Calling `destroy` on an Active Service object will send an HTTP `DELETE` request to the API. If you already know the resource, you can save a round trip to the API by using the `destroy` class method.

```ruby
user = User.find(1)
user.destroy
# => DELETE /users/1
user.destroyed?
# => true

User.destroy(1)
# => DELETE /users/1
```

## Validations

Active Service includes `ActiveModel::Validations` so you can define validations similar to Active Record. Models get validated before being sent to the API, saving unnecessary trips if the resource is invalid. 

Any errors returned from the API with a `400` or `422` status are parsed and assigned to the `errors` array.

```ruby
class User < ActiveService::Base
  attribute :name 
  attribute :email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }  
end

user = User.new(email: "bad@email")
user.save
# => false
user.errors.full_messages
# => ["Name can't be blank", "Email is invalid"]
```

## Callbacks

Active Service includes `ActiveModel::Callbacks` so you can define callbacks similar to Active Record. See the documentation on Active Record [callbacks] for details. 

```ruby
class User < ActiveService::Base
  attribute :email
  before_save { |user| user.email = user.email.downcase }
end

user = User.create(email: "FOO@BAR.COM")
# => POST /users { "email": "foo@bar.com" } 
```

The available callbacks are:

* `before_save`
* `before_create`
* `before_update`
* `before_destroy`
* `after_save`
* `after_create`
* `after_update`
* `after_destroy`

## Attributes

Active Service uses [ActiveAttr](https://github.com/cgriego/active_attr) under the hood
for most of its attribute magic.

```ruby
class User < ActiveService::Base
  attribute :name # plain string attribute
  attribute :admin, default: false # attribute w/ default
  attribute :active, type: Boolean # type casted attribute
  attribute :email, source: 'UserEmail' # attribute with different source name
  attribute :role, values: %w(admin editor moderator) # attribute with possible values
end
```

We've also added a few enhancements of our own to make integrating with APIs easier.

### Mapping JSON attributes to different names

Transform JSON attributes from the API to different names on your model by specifying a `source` option on the `attribute`. Active Service will take care of mapping the `attribute` to/from JSON.

```ruby
class User < ActiveService::Base
  attribute :name, source: "UserName"
end

user = User.find(1)
# => GET /users/1 returns { "id": 1, "UserName": "foo" }
user.name
# => "foo"

users = User.where(name: "foo")
# => GET /users?UserName=foo
```

### Assigning a list of possible values

Often an API has attributes with a possible list of values. Define these values 
by specifying a `values` option on the `attribute`. Active Service will provide 
predicates and scopes for each of the values.

```ruby
class Purchase < ActiveService::Base
  attribute :status, values: %w(in_progress submitted approved shipped)
end

purchase = Purchase.new(status: "approved")
purchase.approved? # => true
purchase.submitted? # => false

purchases = Purchase.shipped
# => GET /purchases?status=shipped
```

## Associations

Setting up associations between resources should be familiar to anyone who uses Active Record. Examples in this section use the following models:

```ruby
class User < ActiveService::Base
  attribute :name
  attribute :organization_id  
  has_many :comments
  has_one :role
  belongs_to :organization
end

class Comment < ActiveService::Base
  attribute :content 
end

class Role < ActiveService::Base
  attribute :name
end

class Organization
  attribute :name
end
```

### Fetching data

Calling an association sends an HTTP request with the complete path

```ruby
user = User.find(1)
# => GET /users/1

user.comments
# => GET /users/1/comments
[#<Comment id=1>, #<Comment id=2>]

user.comments.where(content: "foo")
# => GET /users/1/comments?content=foo

user.role
# => GET /users/1/role
# => #<Role id=1>

user.organization
# => :organization_id on user is used to build the path
# => GET /organizations/1
# => #<Organization id=1>

user.comment_ids
# => GET /users/1/comments
[1,2]
```

Subsequent calls to an association will return the cached objects instead of sending a new HTTP request.

### Creating data

Calling `build` on an association will return a new instance of your model without sending an HTTP request. Calling `create` on an association will issue an HTTP POST request to the complete path.

```ruby
user = User.find(1)
# => GET /users/1

comment = user.comments.build(:content => "Hodor Hodor. Hodor.")
# => #<Comment id=nil user_id=1 content="Hodor Hodor. Hodor."> 

comment = user.comments.create(:content => "Hodor Hodor. Hodor.")
# => POST /users/1/comments { "user_id": 1, "content": "Hodor Hodor. Hodor." }
# => #<Comment id=1 user_id=1 content="Hodor Hodor. Hodor.">
```

### Nested attributes

Setup nested attributes for your associations with the usual  `accepts_nested_attributes_for` macro. When you enable nested attribues an attribute reader and attribute writer are created for the association.

```ruby
class User < ActiveService::Base
  attribute :name
  has_many :comments
  accepts_nested_attributes_for :comments
end

user = User.find(1)
# => GET /users/1

user.comments_attributes = [{content: "Hodor Hodor."}, {content: "Hodor."}]
user.comments
# => [#<Comment id=nil user_id=1 content="Hodor Hodor.">, #<Comment id=nil user_id=1 content="Hodor.">]
```

## Scopes

Scopes can be defined on your models using the same syntax as Active Record. Scopes return an `ActiveService::Model::Relation` and can be chained or used within other scopes. 

```ruby
class User < ActiveService::Base
  attribute :name
  attribute :active?
  attribute :admin?
  scope :active, -> { where(active: true) }
  scope :admins, -> { where(admin: true) }
end

admins = User.admins
# => GET /users?admin=true

active_admins = User.active.admins
# => GET /users?active=true&admin=true
```

Scopes are also supported on associations.

```ruby
class User < ActiveService::Base
  attribute :name
  has_many :comments
end

class Comment < ActiveService::Base
  attribute :content
  attribute :approved?
  attribute :user_id
  belongs_to :user
  scope :approved, -> { where(approved: true) }
end

user = User.find(1)
# => GET /users/1

comments = user.comments.approved
# => GET /users/1/comments?approved=true
``` 

## Collections

ActiveService::Collection is a wrapper to handle parsing index responses that
do not directly map to Rails conventions. Implementation details are heavily influenced by ActiveResource::Collection.

If you expect to receive json with nonstandard data, you can 
define a custom parser that inherits from ActiveService::Collection. 
        
GET /posts.json delivers following response body:

```
  {
    posts: [
      {
        title: "ActiveService now has associations",
        body: "Lorem Ipsum"
      }
      {...}
    ]
    next_page: "/posts.json?page=2"
  }
```

A Post class can be setup to handle it with:

```
  class Post < ActiveService::Base
    self.site = "http://example.com"
    self.collection_parser = PostCollection
  end
```

And the collection parser:

```
  class PostCollection < ActiveService::Collection
    attr_accessor :next_page
    def initialize(parsed = {})
      @elements = parsed['posts']
      @next_page = parsed['next_page']
    end
  end
```

The result from a find method that returns multiple entries will now be a 
PostParser instance.  ActiveService::Collection includes Enumerable and
instances can be iterated over just like an array.

```
   @posts = Post.find(:all) # => PostCollection:xxx
   @posts.next_page         # => "/posts.json?page=2"
   @posts.map(&:id)         # => [1, 3, 5 ...]
```

The initialize method will receive the ActiveService::Formats parsed result
and should set @elements.

## Overriding Conventions

Often web services refuse to play nicely and you need to override common behaviors in Active Service. No problem, we've got you covered.

### Custom Paths

You can define custom HTTP paths for your models.

```ruby
class User < ActiveService::Base
  collection_path "employees"
end

User.all
# => GET /employees

User.find(1)
# => GET /employees/1
```

You can also include custom variables in your paths.

```ruby
class User < ActiveService::Base
  attribute :organization_id
  collection_path "organizations/:organization_id/users"
end

User.all(_organization_id: 1)
# => GET /organizations/1/users

User.find(1, _organization_id: 2)
# => GET /organizations/2/users/1
```

### Multiple APIs

Connect your models to a different API using `ActiveService::API.new` and the `uses_api` macro.

```ruby
api = ActiveService::API.new :url => "http://another.api.example.com"

class User < ActiveService::Base
  uses_api api
end

User.all
# => GET http://another.api.example.com/users
```

## Testing

The faraday gem provides support for stubbing requests. With Rspec, we can setup a unique API for our models.

```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.include(Module.new do
    def stub_api_for(klass)
      klass.use_api (api = ActiveService::API.new)
      # Here you would customize this for your own API (URL, middleware, etc)
      # like you have done in your application’s initializer
      api.setup url: "http://api.example.com" do |c|
        c.use ActiveService::Middleware::DefaultParseJSON
        c.adapter(:test) { |s| yield s }
      end
    end
  end)
end

#app/models/user.rb 
class User < ActiveService::Base
  attribute :name
end
```

Then in our tests we create a stub for each HTTP request.

```ruby
# spec/models/user.rb
describe User do
  before do
    stub_api_for(User) do |stub|
      stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Hodor Hodor" }.to_json] }
    end
  end

  describe :find do
    subject(:user) { User.find(1) }
    expect(user.name).to eq "Hodor Hodor"
  end
end
```
