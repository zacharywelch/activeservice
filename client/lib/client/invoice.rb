class Invoice
  include ActiveAttr::Model

  self.base_uri = "https://cafexwstest.careerbuilder.com/v2/accounts/AT-9900479560/Invoices"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :invoice_number 
  attribute :status
  attribute :total
  attribute :account_id

  def self.from_json(json)
    new(
      invoice_number: json["InvoiceNumber"],
      account_id:     json["AccountDID"],
      status:         json["Status"],
      total:          json["Total"]);
  end

  def self.paid

  end
end