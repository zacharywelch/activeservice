# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes::Serializer do

  before do
    api = ActiveService::API.setup url: "https://api.example.com" do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use ActiveService::Middleware::ParseJSON
      builder.adapter :test do |stub|
        stub.get("/users/1") { |env| ok! id: 1, name: "Tobias Fünke", email: "tobias@gmail.com" }
        stub.get("/users/2") { |env| ok! id: 2, name: "Tobias Fünke", email: "tobias@gmail.com", role: { id: 1, name: "Therapist", active: true, user_id: 2 } }
        stub.get("/users/3") { |env| ok! id: 3, name: "Tobias Fünke", email: "tobias@gmail.com", comments: [{ id: 1, body: "They're having a FIRESALE?", approved: true, user_id: 3 }] }
        stub.get("/users/4") { |env| ok! id: 4, name: "Tobias Fünke", email: "tobias@gmail.com", role: { id: 1, name: "Therapist", active: true, user_id: 4 }, comments: [{ id: 1, body: "They're having a FIRESALE?", approved: true }, { id: 2, body: "Is this the tiny town from Footloose?", approved: true }] }
      end
    end

    spawn_model "User" do
      uses_api api
      attribute :name
      attribute :email
      has_one :role
      has_one :profile
      has_many :comments
      has_many :posts
    end

    spawn_model "Comment" do
      attribute :body
      attribute :approved
      attribute :user_id
      belongs_to :user
    end

    spawn_model "Role" do
      attribute :name
      attribute :active
      attribute :user_id
      belongs_to :user
    end

    spawn_model "Profile" do
      attribute :bio
    end

    spawn_model "Post" do
      attribute :content
    end
  end

  context "without associations" do

    let(:resource) { User.find(1) }

    subject(:serializer) do
      ActiveService::Model::Attributes::Serializer.new(resource)
    end

    it "serializes attributes" do
      expect(serializer.serialize).to eq({ id: 1, name: "Tobias Fünke", email: "tobias@gmail.com" })
    end
  end

  context "with nested has_one association" do

    let(:resource) { User.find(2) }

    subject(:serializer) do
      ActiveService::Model::Attributes::Serializer.new(resource)
    end

    it "includes has_one attributes" do
      expect(serializer.serialize).to eq({ id: 2,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           role: {
                                             id: 1,
                                             name: "Therapist",
                                             active: true,
                                             user_id: 2
                                           }
                                         })
    end

    it "includes multiple has_one attributes" do
      resource.profile = Profile.new(bio: "Blue Man Group understudy")
      expect(serializer.serialize).to eq({ id: 2,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           role: {
                                             id: 1,
                                             name: "Therapist",
                                             active: true,
                                             user_id: 2
                                           },
                                           profile: {
                                             bio: "Blue Man Group understudy",
                                             id: nil
                                           }
                                         })
    end

    it "includes nil has_one attributes" do
      resource.profile = nil
      expect(serializer.serialize).to eq({ id: 2,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           role: {
                                             id: 1,
                                             name: "Therapist",
                                             active: true,
                                             user_id: 2
                                           },
                                           profile: nil
                                         })
    end
  end

  context "with nested has_many association" do

    let(:resource) { User.find(3) }

    subject(:serializer) do
      ActiveService::Model::Attributes::Serializer.new(resource)
    end

    it "includes has_many attributes" do
      expect(serializer.serialize).to eq({ id: 3,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           comments: [{
                                             id: 1,
                                             body: "They're having a FIRESALE?",
                                             approved: true,
                                             user_id: 3
                                           }]
                                         })
    end

    it "includes multiple has_many attributes" do
      resource.posts = [Post.new(content: "Frightened Inmate #2")]
      expect(serializer.serialize).to eq({ id: 3,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           comments: [{
                                             id: 1,
                                             body: "They're having a FIRESALE?",
                                             approved: true,
                                             user_id: 3
                                           }],
                                           posts: [{
                                             content: "Frightened Inmate #2",
                                             id: nil
                                           }]
                                         })
    end

    it "includes empty has_many attributes" do
      resource.posts = []
      expect(serializer.serialize).to eq({ id: 3,
                                           name: "Tobias Fünke",
                                           email: "tobias@gmail.com",
                                           comments: [{
                                             id: 1,
                                             body: "They're having a FIRESALE?",
                                             approved: true,
                                             user_id: 3
                                           }],
                                           posts: []
                                         })
    end
  end

  context "when updating changes only" do

    before { User.method_for :update, :patch }
    after  { User.method_for :update, :put }

    let(:resource) { User.find(4) }

    subject(:serializer) do
      ActiveService::Model::Attributes::Serializer.new(resource)
    end

    context "with modified attribute" do

      before { resource.name = "Lindsay" }

      it "only includes modified attribute" do
        expect(serializer.serialize).to eq({ name: "Lindsay", id: 4 })
      end
    end

    context "with modified has_one" do

      before { resource.role.name = "Blue Man Standby" }

      it "includes modified has_one attributes" do
        expect(serializer.serialize).to eq({ role: {
                                               name: "Blue Man Standby",
                                               id: 1
                                             }
                                           })
      end
    end

    context "with modified has_many" do

      before { resource.comments.first.body = "I thought it was a pool toy." }

      it "includes modified has_many attributes" do
        expect(serializer.serialize).to eq({ comments: [{
                                               body: "I thought it was a pool toy.",
                                               id: 1
                                             }]
                                           })
      end
    end
  end

  context "when creating changes only" do

    let(:user) { User.find(1) }

    context "with new has_one" do

      before { Role.method_for :create, :patch }
      after  { Role.method_for :create, :post }

      let(:role) { user.role.build(name: "Blue Man Standby") }

      subject(:serializer) do
        ActiveService::Model::Attributes::Serializer.new(role)
      end

      it "includes modified has_one attributes" do
        expect(serializer.serialize).to eq({ name: "Blue Man Standby",
                                             id: nil,
                                             user_id: 1
                                           })
      end
    end

    context "with new has_many" do

      before { Role.method_for :create, :patch }
      after  { Role.method_for :create, :post }

      let(:comment) { user.comments.build(body: "I thought it was a pool toy.") }

      subject(:serializer) do
        ActiveService::Model::Attributes::Serializer.new(comment)
      end


      it "includes modified has_many attributes" do
        expect(serializer.serialize).to eq({ body: "I thought it was a pool toy.",
                                             id: nil,
                                             user_id: 1
                                           })
      end
    end
  end
end
