# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes::NestedAttributes do
  context "with a belongs_to association" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        belongs_to :company, :path => "/organizations/:id", :foreign_key => :organization_id
        accepts_nested_attributes_for :company
      end

      spawn_model "Company" do
        uses_api api
        attribute :name
      end

      @user_with_data_through_nested_attributes = User.new :name => "Test", :company_attributes => { :name => "Example Company" }
    end

    context "when child does not yet exist" do
      it "creates an instance of the associated class" do
        expect(@user_with_data_through_nested_attributes.company).to be_a(Company)
        expect(@user_with_data_through_nested_attributes.company.name).to eq "Example Company"
      end
    end

    context "when child does exist" do
      it "updates the attributes of the associated object" do
        @user_with_data_through_nested_attributes.company_attributes = { :name => "Fünke's Company" }
        expect(@user_with_data_through_nested_attributes.company).to be_a(Company)
        expect(@user_with_data_through_nested_attributes.company.name).to eq "Fünke's Company"
      end
    end
  end

  context "with a has_one association" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_one :pet
        accepts_nested_attributes_for :pet
      end

      spawn_model "Pet" do
        uses_api api
        attribute :name
        attribute :user_id
      end

      @user_with_data_through_nested_attributes = User.new :name => "Test", :pet_attributes => { :name => "Hasi" }
    end

    context "when child does not yet exist" do
      it "creates an instance of the associated class" do
        expect(@user_with_data_through_nested_attributes.pet).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes.pet.name).to eq "Hasi"
      end
    end

    context "when child does exist" do
      it "updates the attributes of the associated object" do
        @user_with_data_through_nested_attributes.pet_attributes = { :name => "Rodriguez" }
        expect(@user_with_data_through_nested_attributes.pet).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes.pet.name).to eq "Rodriguez"
      end
    end
  end

  context "with a has_many association" do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_many :pets
        accepts_nested_attributes_for :pets
      end

      spawn_model "Pet" do
        uses_api api
        attribute :name
      end

      @user_with_data_through_nested_attributes = User.new :name => "Test", :pets_attributes => [{ :name => "Hasi" }, { :name => "Rodriguez" }]
    end

    context "when children do not yet exist" do
      it "creates an instance of the associated class" do
        expect(@user_with_data_through_nested_attributes.pets.length).to eq 2
        expect(@user_with_data_through_nested_attributes.pets[0]).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes.pets[1]).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes.pets[0].name).to eq "Hasi"
        expect(@user_with_data_through_nested_attributes.pets[1].name).to eq "Rodriguez"
      end
    end
  end

  context "with a has_many association as a Hash" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.use Faraday::Request::UrlEncoded
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        has_many :pets
        accepts_nested_attributes_for :pets
      end

      spawn_model "Pet" do
        uses_api api
        attribute :name
      end

      @user_with_data_through_nested_attributes_as_hash = User.new :name => "Test", :pets_attributes => { '0' => { :name => "Hasi" }, '1' => { :name => "Rodriguez" }}
    end

    context "when children do not yet exist" do
      it "creates an instance of the associated class" do
        expect(@user_with_data_through_nested_attributes_as_hash.pets.length).to be 2
        expect(@user_with_data_through_nested_attributes_as_hash.pets[0]).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes_as_hash.pets[1]).to be_a(Pet)
        expect(@user_with_data_through_nested_attributes_as_hash.pets[0].name).to eq "Hasi"
        expect(@user_with_data_through_nested_attributes_as_hash.pets[1].name).to eq "Rodriguez"
      end
    end
  end

  context "with an unknown association" do
    it "raises an error" do
      expect {
        spawn_model("User") { accepts_nested_attributes_for :company }
      }.to raise_error(ActiveService::Errors::AssociationUnknownError, 'Unknown association name :company')
    end
  end
end
