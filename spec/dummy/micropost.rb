class Micropost < ActiveService::Base

  self.base_uri = "http://localhost:3000/api/v1/microposts"

  attribute :content, field: 'content'
  attribute :user_id, field: 'user_id'
  attribute :created_at, field: 'created_at'
  attribute :updated_at, field: 'updated_at'

  belongs_to :user

  validates :user_id, presence: true
  validates :content, presence: true, length: { maximum: 140 }
end
