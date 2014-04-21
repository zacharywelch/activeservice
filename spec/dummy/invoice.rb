class Invoice < ActiveService::Base
  
  attribute :number, field: 'invoice_number'
  attribute :due_at, type: Date
  attribute :sent_at, type: Date
  attribute :amount

  def self.search(params)
    columns = [ :id, :amount, :page, :perpage ]
    where(params.symbolize_keys.sanitize(*columns))
  end  
end
