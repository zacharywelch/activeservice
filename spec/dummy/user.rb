class User < ActiveService::Base
  self.base_uri = "http://localhost:8888/api/v1"
  
  attribute :name
  attribute :email

  has_many :microposts

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }  

  before_save { |user| user.email = user.email.downcase }  
end


# class User < ActiveRecord::Base
  
#   has_many :microposts

#   VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

#   validates :name,  presence: true, length: { maximum: 50 }
#   validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }  

#   before_save { |user| user.email = user.email.downcase }    
# end
