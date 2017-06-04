# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes::Symbolizer do

  before do
    api = ActiveService::API.setup url: "https://api.example.com" do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use ActiveService::Middleware::ParseJSON
      builder.adapter :test do |stub|
        stub.get("/users/1") { |env| ok! id: 1, name: "Tobias Fünke", email: "tobias@gmail.com", role: { id: 1, name: "Therapist", active: true }, comments: [{ body: "They're having a FIRESALE?", approved: true }, { body: "Is this the tiny town from Footloose?", approved: true }] }
      end
    end

    spawn_model "User" do
      uses_api api
      attribute :name
      attribute :email
      has_one :role
      has_many :comments
    end

    spawn_model "Comment" do
      uses_api
      attribute :body
      attribute :approved
    end

    spawn_model "Role" do
      uses_api
      attribute :name
      attribute :active
    end
  end

  context "when updating changes only" do

    before { User.method_for :update, :patch }
    after  { User.method_for :update, :put }

    let(:resource) { User.find(1) }

    subject(:symbolizer) do
      ActiveService::Model::Attributes::Symbolizer.new(resource)
    end

    context "with modified attribute" do

      before { resource.name = "Lindsay" }

      it "only includes modified attribute" do
        expect(symbolizer.symbolize).to eq({ name: "Lindsay" })
      end
    end

    context "with modified has_one" do

      before { resource.role.name = "Blue Man Standby" }

      it "includes modified has_one attributes" do
        expect(symbolizer.symbolize).to eq({ role: { name: "Blue Man Standby" } })
      end
    end

    context "with modified has_many" do

      before { resource.comments.first.body = "I'm afraid I have a mess on my hands." }

      it "includes modified has_many attributes" do
        expect(symbolizer.symbolize).to eq({ comments: [{ body: "I'm afraid I have a mess on my hands." }] })
      end
    end
  end
end
