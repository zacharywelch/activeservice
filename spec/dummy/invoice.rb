class Invoice < ActiveService::Base

  self.base_uri = "https://cafexwstest.careerbuilder.com/v2/Invoices"
  self.headers  = { Authorization: "Partner careerbuilder:1n73rnal" }

  attribute :id, field: 'InvoiceNumber'
  attribute :due_at, field: 'AgingDt', type: Date
  attribute :sent_at, field: 'EmailSentDT', type: Date
  attribute :status, field: 'Status'
  attribute :amount, field: 'Total'
  attribute :account_id, field: 'ExternalAcctID'
  attribute :contract_id, field: 'ContractDID'
  attribute :billing_address_street, field: 'BillAddress1'
  attribute :billing_address_line_2, field: 'BillAddress2'
  attribute :billing_address_locale, field: 'BillLocale1'
  attribute :billing_address_country, field: 'BillLocale2'

  composed_of :billing_address, 
              :class_name => 'Address', 
              :mapping    => [ %w(billing_address_street street),
                               %w(billing_address_line_2 line_2),
                               %w(billing_address_locale locale),
                               %w(billing_address_country country) ]

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