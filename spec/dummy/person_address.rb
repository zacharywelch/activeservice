class PersonAddress < ActiveService::Base
  attribute :first_name
  attribute :last_name

  attribute :address_street
  attribute :address_city
  attribute :address_state
  attribute :address_zip
  attribute :address_country

  composed_of :address, mapping: [ 
    %w(address_street street),
    %w(address_city city),
    %w(address_state state),
    %w(address_zip zip),
    %w(address_country country) ]
end