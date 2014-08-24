# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Aggregations do
  describe :composed_of do
    context "with multiple value object" do
      before do
        spawn_model "User" do
          attribute   :address_street
          attribute   :address_city
          composed_of :address, mapping: [ %w(address_street street), %w(address_city city) ] 
        end

        class Address
          attr_reader :street, :city
          def initialize(attributes = {})
            @street  = attributes[:street]
            @city    = attributes[:city]
          end
        end
      end

      subject(:user) { User.new(:address_street => "123 Sesame St.", :address_city => "New York City") }

      it "maps address attributes" do
        expect(user.address.street).to eq "123 Sesame St."
        expect(user.address.city).to eq "New York City"
      end

      it "maintains original attributes" do
        expect(user.address_street).to eq "123 Sesame St."
        expect(user.address_city).to eq "New York City"
      end

      it "handles respond_to for getter" do
        expect { user.address }.not_to raise_error()
        expect(user.address).to be_kind_of(Address)
      end

      it "handles respond_to for setter" do
        expect(user).to respond_to :address=
      end      

      it "updates aggregation when attributes are updated" do
        user.address_street = "New Street"
        user.address_city = "New City"
        expect(user.address.street).to eq "New Street"
        expect(user.address.city).to eq "New City"
      end

      it "updates attributes when aggregation is updated" do
        user.address = Address.new(:street => "New Street", :city => "New City")
        expect(user.address_street).to eq "New Street"
        expect(user.address_city).to eq "New City"
      end

      it "handles nil assignment" do
        user.address = nil
        expect(user.address).to_not be_nil
        expect(user.address.street).to be_nil
        expect(user.address.city).to be_nil
        expect(user.address_street).to be_nil
        expect(user.address_city).to be_nil
      end
    end

    context "with class_name option" do
      before do
        spawn_model "User" do
          attribute   :address_street
          attribute   :address_city
          composed_of :work_address, class_name: 'Address', mapping: [ %w(address_street street), %w(address_city city) ] 
        end

        class Address
          attr_reader :street, :city
          def initialize(attributes = {})
            @street  = attributes[:street]
            @city    = attributes[:city]
          end
        end

        class BadAddress; end
      end

      subject(:user) { User.new(:address_street => "123 Sesame St.", :address_city => "New York City") }

      it "maps to class with different class_name" do
        expect(user.work_address.street).to eq "123 Sesame St."
        expect(user.work_address.city).to eq "New York City"
        expect(user.work_address).to be_kind_of(Address)
      end

      it "handles assignment of aggregation with different class_name" do
        address = Address.new(:street => "New Street", :city => "New City")
        expect { user.work_address = address }.not_to raise_error()
        expect { user.work_address = BadAddress.new }.to raise_error()
      end
    end
  end
end
