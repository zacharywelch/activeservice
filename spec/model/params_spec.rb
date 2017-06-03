# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Params do

  context "when include_root_in_json is set" do
    context "to true" do
      before do
        api = ActiveService::API.setup url: "https://api.example.com" do |builder|
          builder.use Faraday::Request::UrlEncoded
          builder.use ActiveService::Middleware::ParseJSON
          builder.adapter :test do |stub|
            stub.post("/users") { |env| ok! user: { id: 1, name: params(env)[:user][:name] } }
            stub.post("/users/admins") { |env| ok! user: { id: 1, name: params(env)[:user][:name] } }
          end
        end

        spawn_model "User" do
          uses_api api
          attribute :name
          include_root_in_json true
          parse_root_in_json true
          custom_post :admins, on: :member
        end
      end

      it "wraps params in the element name in `to_params`" do
        user = User.new(name: "Tobias Fünke")
        expect(user.to_params).to eq({ user: { name: "Tobias Fünke", id: nil } })
      end

      it "wraps params in the element name in `.create`" do
        user = User.admins(name: "Tobias Fünke")
        expect(user.name).to eq "Tobias Fünke"
      end
    end

    context "to a symbol" do
      before do
        spawn_model "User" do
          attribute :name
          include_root_in_json :person
          parse_root_in_json :person
        end
      end

      it "wraps params in the specified value" do
        user = User.new(name: "Tobias Fünke")
        expect(user.to_params).to eq({ person: { name: "Tobias Fünke", id: nil } })
      end
    end

    context "in the parent class" do
      before do
        spawn_model "Model" do
          include_root_in_json true
        end

        class User < Model
          attribute :name
        end
        @spawned_models << :User
      end

      it "wraps params with the class name" do
        user = User.new(name: "Tobias Fünke")
        expect(user.to_params).to eq({ user: { name: "Tobias Fünke", id: nil } })
      end
    end
  end

  context "when to_params is set" do
    before do
      api = ActiveService::API.setup url: "https://api.example.com" do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! id: 1, name: params(env)['name'] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        def to_params
          { id: nil, name: "Lindsay Fünke" }
        end
      end
    end

    it "changes the request parameters for one-line resource creation" do
      user = User.create(name: "Tobias Fünke")
      expect(user.name).to eq "Lindsay Fünke"
    end

    it "changes the request parameters for Model.new + #save" do
      user = User.new(name: "Tobias Fünke")
      user.save
      expect(user.name).to eq "Lindsay Fünke"
    end
  end

  context "when include_root_in_json set json_api" do
    before do
      api = ActiveService::API.setup url: "https://api.example.com" do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! users: [{ id: 1, name: params(env)[:users][:name] }] }
        end
      end
    end

    context "to true" do
      before do
        spawn_model "User" do
          uses_api api
          include_root_in_json true
          parse_root_in_json true, format: :json_api
          custom_post :admins, on: :collection
          attribute :name
        end
      end

      it "wraps params in the element name in `to_params`" do
        user = User.new(name: "Tobias Fünke")
        expect(user.to_params).to eq({ users: [{ name: "Tobias Fünke", id: nil }] })
      end

      it "wraps params in the element name in `.where`" do
        user = User.where(name: "Tobias Fünke").build
        expect(user.name).to eq"Tobias Fünke"
      end
    end
  end

  context "without embedded associations" do
    before do
      spawn_model "User" do
        attribute :name
      end
    end

    it "only sends attributes as params" do
      user = User.new(name: "Tobias Fünke")
      expect(user.to_params).to eq({ name: "Tobias Fünke", id: nil })
    end
  end

  context "with embedded has_one association" do
    before do
      spawn_model "User" do
        attribute :name
        has_one :role
        has_one :profile
      end

      spawn_model "Role" do
        attribute :name
      end

      spawn_model "Profile" do
        attribute :bio
      end
    end

    it "includes has_one attributes in params" do
      user = User.new(name: "Tobias Fünke")
      user.role = Role.new(name: "Therapist")

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     role: {
                                       name: "Therapist",
                                       id: nil
                                     }
                                   })
    end

    it "includes multiple has_one attributes in params" do
      user = User.new(name: "Tobias Fünke")
      user.role = Role.new(name: "Therapist")
      user.profile = Profile.new(bio: "Blue Man Group understudy")

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     role: {
                                       name: "Therapist",
                                       id: nil
                                     },
                                     profile: {
                                       bio: "Blue Man Group understudy",
                                       id: nil
                                     }
                                   })
    end

    it "includes nil has_one in params" do
      user = User.new(name: "Tobias Fünke")
      user.role = nil

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     role: nil
                                   })
    end
  end

  context "with embedded has_many association" do
    before do
      spawn_model "User" do
        attribute :name
        has_many :comments
        has_many :posts
      end

      spawn_model "Comment" do
        attribute :body
      end

      spawn_model "Post" do
        attribute :content
      end
    end

    it "includes has_many attributes in params" do
      user = User.new(name: "Tobias Fünke")
      user.comments = [Comment.new(body: "They're having a FIRESALE?")]

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     comments: [{
                                       body: "They're having a FIRESALE?",
                                       id: nil
                                     }]
                                   })
    end

    it "includes multiple has_many attributes in params" do
      user = User.new(name: "Tobias Fünke")
      user.comments = [Comment.new(body: "They're having a FIRESALE?")]
      user.posts = [Post.new(content: "I'm afraid I have something of a mess on my hands.")]

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     comments: [{
                                       body: "They're having a FIRESALE?",
                                       id: nil
                                     }],
                                     posts: [{
                                       content: "I'm afraid I have something of a mess on my hands.",
                                       id: nil
                                     }]
                                   })
    end

    it "includes empty has_many in params" do
      user = User.new(name: "Tobias Fünke")
      user.comments = []

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     id: nil,
                                     comments: []
                                   })
    end
  end

  context "when update method is PATCH instead of PUT" do
    before do
      spawn_model "User" do
        attribute :name
        attribute :email
        has_one :role
        has_many :comments
        method_for :update, :patch
      end

      spawn_model "Comment" do
        attribute :body
        attribute :approved
      end

      spawn_model "Role" do
        attribute :name
        attribute :active
      end
    end

    after { User.method_for :update, :put }

    xit "only includes the attributes that were modified" do
      user = User.new(name: "Tobias Fünke")
      expect(user.to_params).to eq({ name: "Tobias Fünke" })
    end

    xit "includes has one associations that were modified" do
      user = User.new(name: "Tobias Fünke")
      user.role = Role.new(name: "Therapist")

      expect(user.to_params).to eq({
                                     name: "Tobias Fünke",
                                     role: {
                                      name: "Therapist"
                                     }
                                   })
    end
  end
end
