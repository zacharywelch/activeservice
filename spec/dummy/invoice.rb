class Invoice < ActiveService::Base
  # self.base_uri = "http://localhost:8888/api/v1/invoices"

  attribute :number, field: 'invoice_number'
  attribute :due_at, type: Date
  attribute :sent_at, type: Date
  attribute :amount

  def self.search(params)
    columns = [ :id, :amount, :page, :perpage ]
    where(params.symbolize_keys.sanitize(*columns))
  end  
end
