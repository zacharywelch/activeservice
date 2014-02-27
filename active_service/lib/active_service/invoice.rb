class Invoice
  include ActiveAttr::Model

  #self.base_uri = "https://cafexwstest.careerbuilder.com/v2/accounts/AT-9900479560/Invoices"
  self.base_uri = "https://cafexwstest.careerbuilder.com/v2/Invoices"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :id 
  attribute :number
  attribute :due_at
  attribute :status 
  attribute :amount

  def from_json(json)
    hash = JSON.parse(json)
    self.attributes = {
      "id" => hash["InvoiceDID"],
      "number" => hash["InvoiceNumber"],
      "due_at" => Date.parse(hash["EndDT"]),
      "status" => hash["Status"],
      "amount" => hash["Total"]
    }
    self
  end

  def paid?
    status == "CLS" 
  end

  def self.open
    where(status: "OPN")
  end

  def self.paid
    where(status: "CLS")
  end
end