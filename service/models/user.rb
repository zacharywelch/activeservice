class User < ActiveRecord::Base
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

  validates :name,  presence: true, uniqueness: true, 
    length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true, 
    format: { with: VALID_EMAIL_REGEX }  

  before_save { |user| user.email = user.email.downcase }  

  def to_json
    super(:except => [:created_at, :updated_at])
  end
end