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

Calling `destroy` on an Active Service object will send an HTTP `DELETE` request to the API. If you already know the resource, you can save a trip to the API by using the `destroy` class method.

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
# => POST /users { "email": "bad@email" } 
# =>   returns 400 { "name": ["can't be blank"], "email": ["is invalid"] }
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
```

Subsequent calls to an association will return the cached objects instead of sending a new HTTP request.

### Creating data

Calling `build` on an association will return a new instance of your model without sending an HTTP request. Calling `create` on an association will issue an HTTP POST request to the complete path.

```ruby
user = User.find(1)
# => GET /users/1

comment = user.comments.build(:content => "Hodor Hodor. Hodor.")
# => #<Comment id=nil user_id=1 content="Hodor Hodor. Hodor"> 

comment = user.comments.create(:content => "Hodor Hodor. Hodor.")
# => POST /users { "user_id": 1, "content": "Hodor Hodor. Hodor." }
# => #<Comment id=1 user_id=1 content="Hodor Hodor. Hodor">
```