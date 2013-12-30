# ServiceClient

Service Client implements object-relational mapping for web services. Like ActiveRecord, its chief aim is to reduce the amount of code needed for object persistence. This is made possible through an interface that’s [Active Model][active_model] compliant and provides transparent proxying between the client and service.

[active_model]: https://github.com/rails/rails/tree/master/activemodel
[active_attr]: https://github.com/cgriego/active_attr
[typhoeus]: https://github.com/typhoeus/typhoeus
[activerecord_callbacks]: http://api.rubyonrails.org/classes/ActiveRecord/Callbacks.html

## Examples

### Defining Service Client Models

ServiceClient extends the [ActiveAttr][active_attr] module with additional features such as Active Model callbacks and object persistence via [Typhoeus][typhoeus]. To create your model first include ActiveAttr::Model

```ruby
class User
  include ActiveAttr::Model
end

# Define attributes for your model
class User
  include ActiveAttr::Model

  attribute :name 
  attribute :email
end

user = User.new(name: 'foo', email: 'foo@bar.com')
user.name #=> "foo"
user.email #=> "foo@bar.com"

# Declare defaults for your model
class User
  include ActiveAttr::Model

  attribute :name 
  attribute :email
  attribute :admin, default: false
end

user = User.new(name: 'foo', email: 'foo@bar.com')
user.admin? #=> false
```

### Validations

Service Client uses Active Model for validation support. Add validations the same way you would using Active Record. Service Client will validate models before requests are sent to the service, saving a round trip to the server.

```ruby
class User
  include ActiveAttr::Model

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

Service Client defines Active Model callbacks matching the life cycle of Active Record objects. See the ActiveRecord [documentation][activerecord_callbacks] for details.

```ruby
class User
  include ActiveAttr::Model

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

Provide an api endpoint for your models and Service Client will handle CRUD operations with your service backend.

```ruby
class User
  include ActiveAttr::Model

  self.base_uri = "http://api.com/v1/users"
end
```

#### Read

Service Client provides an API familiar to Active Record users for accessing resources. Below are a few examples of different data access methods provided by Service Client.

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
user = user.find(166)
=> #<User email: "foo@bar.com", id: 166, name: "foo"> 

user.destroyed? #=> false
user.destroy #=> true
user.destroyed? #=> true

# Delete a record on the fly
User.destroy(166) #=> true
user = User.find(166) #=> nil 
```