# = ActiveAttr
# 
# ActiveAttr provides most of the ActiveModel functionality in ActiveService. 
# Here we patch ActiveAttr with additional features needed by ActiveService 

class ActiveAttr::AttributeDefinition
  
  # Maps a source field to an attribute on the model 
  #
  # When a GET is requested for a resource and the response has fields that 
  # are named differently from the attributes on your model, use <tt>field</tt> 
  # to map them appropriately.
  #
  #   # GET https://api.com/users/1.json
  #   #
  #   # Response (200):
  #   # { "UserID": 1, "UserName": "foo", "UserEmail": "foo@bar.com" }
  #   
  #   class User < ActiveService::Base
  #
  #     attribute :id,    field: 'UserID'
  #     attribute :name,  field: 'UserName'
  #     attribute :email, field: 'UserEmail'
  #   end
  #
  #   user = User.find(1)
  #   user.name => "foo"
  #   user.email => "foo@bar.com"
  #
  def field
    options[:field] || name.to_s
  end
end