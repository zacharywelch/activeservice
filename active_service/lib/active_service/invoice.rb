class Invoice
  include ActiveAttr::Model

  self.base_uri = "https://cafexwstest.careerbuilder.com/v2/accounts/AT-9900479560/Invoices"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :invoice_number 
  attribute :status
  attribute :total
  attribute :account_id

  def from_json(json)
    hash = JSON.parse(json)
    self.attributes = {
      "invoice_number" => hash["InvoiceNumber"],
      "account_id"     => hash["AccountDID"],
      "status"         => hash["Status"],
      "total"          => hash["Total"]
    }
    self
  end

  def self.paid

  end
end