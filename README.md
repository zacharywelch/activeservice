# ActiveService

ActiveService is an ORM that maps REST resources to Ruby objects using an ActiveRecord-like interface. 

## Getting Started

Setup an API for your ActiveService models to use. For Rails this would go in a service initalizer like `config/initializers/active_service.rb`

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

Creating your ActiveService models is simple. Inherit from `ActiveService::Base` and define your attributes.

```ruby
class User < ActiveService::Base
  attribute :name
end
```

That's it! Now you can communicate with the API using ActiveRecord syntax.

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

ActiveRecord objects are mapped to a database via SQL `SELECT`, `INSERT`, `UPDATE`, and `DELETE` statements. With ActiveService, objects are mapped to a resource via HTTP `GET`, `POST`, `PUT` and `DELETE` requests.

### Create

Creating resources with ActiveService is similar to ActiveRecord.

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

ActiveService provides a rich API for accessing resources. A lot of the syntatic sugar you've come to love with ActiveRecord is available in ActiveService.

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

Once an ActiveService object has been retrieved, its attributes can be modified and sent back to the API in a `PUT` request. 

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

Calling `destroy` on an ActiveService object will send an HTTP `DELETE` request to the API. If you already know the resource, you can save a trip to the API by using the `destroy` class method.

```ruby
user = User.find(1)
user.destroy
# => DELETE /users/1
user.destroyed?
# => true

User.destroy(1)
# => DELETE /users/1
```
