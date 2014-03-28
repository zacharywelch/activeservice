class Address
  attr_reader :street, :city, :state, :zip, :country

  def initialize(attributes={})
    @street  = attributes[:street]
    @city    = attributes[:city]
    @state   = attributes[:state]
    @zip     = attributes[:zip]
    @country = attributes[:country]
  end
end