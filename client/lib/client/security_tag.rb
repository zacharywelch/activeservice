class SecurityTag
  include ActiveAttr::Model

  self.base_uri = "https://cafexwstest.careerbuilder.com/v1/securitytags"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :name
  attribute :description
  attribute :owner
  attribute :active, :default => true
  attribute :audited, :default => false
  
  validates :name, :description, :owner, :active, :audited, presence: true
  validates :description, length: { maximum: 50 }

  def self.all
    super(from: "#{base_uri}/getsecuritytags", response_key: "ResponseData")
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