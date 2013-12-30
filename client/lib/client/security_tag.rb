class SecurityTag
  include ActiveAttr::Model

  self.base_uri = "http://localhost:3000/api/v1/securitytags"

  attribute :name
  attribute :description
  attribute :owner
  attribute :active, :default => true
  attribute :audited, :default => false
  
  validates :name, :description, :owner, :active, :audited, presence: true
  validates :description, length: { maximum: 50 }

  def self.all
    super(from: "#{base_uri}/GetSecurityTags")
  end

  def self.from_json(json)
    new(
      name:        json["SecurityTag"],
      description: json["Description"],
      active:      json["ActiveFlag"],
      owner:       json["BusinessOwner"],
      audited:     json["AuditFlg"])
  end
end