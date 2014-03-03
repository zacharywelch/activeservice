class Invoice
  include ActiveService::Model

  #self.base_uri = "https://cafexwstest.careerbuilder.com/v2/accounts/AT-9900479560/Invoices"
  self.base_uri = "https://cafexwstest.careerbuilder.com/v2/Invoices"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :id,     field: 'InvoiceDID'
  attribute :number, field: 'InvoiceNumber'
  attribute :due_at, field: 'EndDT', type: Date
  attribute :status, field: 'Status'
  attribute :amount, field: 'Total'

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