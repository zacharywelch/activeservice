# ActiveService

ActiveService is an ORM that maps REST resources to Ruby objects using an ActiveRecord-like interface. 

## Getting Started

1. Setup an API for your ActiveService models to use. For Rails this would go in a service initalizer like config/initializers/active_service.rb

```ruby
# Setup a default API for your application
ActiveService::API.setup :url => "http://api.example.com" do |c|
  c.use Faraday::Request::UrlEncoded
  c.use ActiveService::Middleware::DefaultParseJSON
  c.use Faraday::Adapter::NetHttp
end
```

## Examples

### Defining Active Service Models

```ruby
# To create your model first inherit from ActiveService::Base
class User < ActiveService::Base
end

# Define attributes for your model
class User < ActiveService::Base

  attribute :name 
  attribute :email
end

user = User.new(name: 'foo', email: 'foo@bar.com')
user.name #=> "foo"
user.email #=> "foo@bar.com"

# Declare defaults for your model
class User < ActiveService::Base

  attribute :name 
  attribute :email
  attribute :admin, default: false
end

user = User.new(name: 'foo', email: 'foo@bar.com')
user.admin? #=> false

# Map fields from a service to your attribute names
class User < ActiveService::Base

  attribute :name, field: "UserName"
  attribute :email, field: "Email"
  attribute :admin, field: "AdminFlag"
end
```

### Validations

ActiveService uses Active Model for validation support. Add validations the same way you would using Active Record. Active Service will validate models before requests are sent to the service, saving a round trip to the server.

```ruby
class User < ActiveService::Base

  attribute :name 
  attribute :email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }  
end

user = User.new(name: 'foo')
user.save #=> false
user.errors.count #=> 1
user.errors.messages #=> {:email=>["can't be blank", "is invalid"]}
user.errors.full_messages #=> ["Email can't be blank", "Email is invalid"]
```

### Callbacks

Active Service defines Active Model callbacks matching the life cycle of Active Record objects. See the ActiveRecord [documentation on callbacks][activerecord_callbacks] for details.

```ruby
class User < ActiveService::Base

  attribute :name 
  attribute :email

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }  

  before_save { |user| user.email = user.email.downcase }  
end

user = User.new(name: 'foo', email: 'FOO@BAR.COM')
user.save #=> true
user.email #=> "foo@bar.com"
```

### CRUD

Provide a base uri for your model and Active Service will handle CRUD operations with the service backend.

```ruby
class User < ActiveService::Base

  self.base_uri = "http://api.com/v1"
end
```

You can also configure Active Service with a base_uri for all your models.

```ruby
# config/environments/development.rb
ActiveService::Config.base_uri = "http://api.com/v1"
```

#### Read

Active Service provides an API familiar to Active Record users for accessing resources. Below are a few examples of different data access methods provided by Active Service.

```ruby
# Find a record by id
user = User.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

# Find all records
users = User.all
=> [#<User email: "foo@bar.com", id: 167, name: "foo">, #<User email: "foo@baz.com", id: 168, name: "baz">] 

# Find first record
user = User.first
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

# Find last record
user = User.last
=> #<User email: "foo@baz.com", id: 167, name: "baz"> 

# Find all records by a where clause
# Any attributes with a field defined get mapped automatically before the 
# service is called
users = User.where(email: 'foo@bar.com')
=> [#<User email: "foo@bar.com", id: 167, name: "foo">] 

# Get a count of all records
User.count #=> 167
```

#### Create
```ruby
# Create an object on the fly
user = User.create(name: 'foo', email: 'foo@bar.com')
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

user.persisted? #=> true

# Instantiate an object and save
user = User.new
=> #<User email: nil, id: nil, name: nil> 

user.new? #=> true
user.persisted? #=> false

user.name = 'foo'
user.email = 'foo@bar.com'
user.save #=> true

user.new? #=> false
user.persisted? #=> true
user.id #=> 166
```

#### Update 
```ruby

# Update a record
user = User.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

user.email = 'foo@baz.com'
user.save #=> true
user.email #=> 'foo@baz.com'

# Update attributes and save 

user = User.find(166)
user.email #=> "foo@bar.com"
user.update_attributes(email: 'foo@baz.com') #=> true
user.email #=> "foo@baz.com"
```

#### Delete
```ruby

# Delete a record
user = User.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

user.destroyed? #=> false
user.destroy #=> true
user.destroyed? #=> true

# Delete a record on the fly
User.destroy(166) #=> true
user = User.find(166) #=> nil 
```

### Serialization

Active Service supports serialization to and from JSON.

```ruby
user = User.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

json = user.to_json
=> "{\"id\":166,\"name\":\"foo\",\"email\":\"foo@bar.com\"}" 

user = User.new.from_json(json)
 => #<User email: "foo@bar.com", id: 166, name: "foo"> 
```

### Associations

Active Service provides a familiar interface for defining associations.

```ruby
class User < ActiveService::Base
  self.base_uri = "http://localhost:3000/api/v1/users"

  attribute :name 
  attribute :email
  
  has_many :microposts
end

class Micropost < ActiveService::Base
  self.base_uri = "http://localhost:3000/api/v1/microposts"

  attribute :content 
  attribute :user_id
  attribute :created_at
  attribute :updated_at

  belongs_to :user
end

user = User.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

user.microposts
=> [#<Micropost content: "Lorem ipsum dolor sit amet.", created_at: "2014-03-27T16:15:11Z", id: 625, updated_at: "2014-03-27T16:15:11Z", user_id: 166>, #<Micropost content: "Lorem ipsum dolor sit amet.", created_at: "2014-03-27T16:15:11Z", id: 619, updated_at: "2014-03-27T16:15:11Z", user_id: 166>]

micropost = Micropost.find(625)
=> #<Micropost content: "Lorem ipsum dolor sit amet.", created_at: "2014-03-27T16:15:11Z", id: 625, updated_at: "2014-03-27T16:15:11Z", user_id: 166>

micropost.user
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 
```

### Aggregations

Active Service implements aggregation in a similar fashion to ActiveRecord using
a composed_of macro.

```ruby
class Person < ActiveService::Base
  attribute :address_street
  attribute :address_city
  
  composed_of :address, mapping: [ %w(address_street street), %w(address_city city) ]
end

class Address
  attr_reader :street, :city
  def initialize(street, city)
    @street, @city = street, city
  end
end

customer.address_street = "123 Sesame St"
customer.address_city   = "Taipei"
customer.address        # => Address.new("123 Sesame St", "Taipei")
```
