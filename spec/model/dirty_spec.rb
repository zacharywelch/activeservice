# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe "ActiveService::Model and ActiveAttr::Dirty" do

  describe "checking dirty attributes" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.request :url_encoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| ok! id: 1, name: "Lindsay Fünke", email: "lindsay@gmail.com" }
          stub.put("/users/1") { |env| ok! id: 1, name: "Tobias Fünke", email: "lindsay@gmail.com" }
          stub.get("/users/2") { |env| ok! id: 2, name: "Maeby Fünke" }
          stub.put('/users/2') { |env| error! :email => ["can't be blank"] }
          stub.post('/users') { |env| ok! id: 3, name: "Tobias Fünke" }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        attribute :email
      end
    end

    context "for existing resource" do

      let(:user) { User.find(1) }

      it "has no changes" do
        expect(user.changes).to be_empty
        expect(user).to_not be_changed
      end

      context "with successful save" do

        it "tracks dirty attributes" do
          user.name = "Tobias Fünke"
          expect(user.name_changed?).to be_truthy
          expect(user.email_changed?).to be_falsey
          expect(user).to be_changed
          user.save
          expect(user).to_not be_changed
        end

        it "tracks only changed dirty attributes" do
          user.name = user.name
          expect(user.name_changed?).to be_falsey
        end

        it "tracks previous changes" do
          user.name = "Tobias Fünke"
          user.save
          expect(user.previous_changes).to eq("name" => ["Lindsay Fünke", "Tobias Fünke"])
        end

        it "tracks dirty attribute on mass assignment" do
          user.assign_attributes(name: "Tobias Fünke")
          expect(user.name_changed?).to be_truthy
          expect(user).to be_changed
          expect(user.changes.length).to eq(1)
        end
      end

      context "with erroneous save" do

        it "tracks dirty attributes" do
          user = User.find(2)
          user.name = "Tobias Fünke"
          expect(user.name_changed?).to be_truthy
          expect(user.email_changed?).to be_falsey
          expect(user).to be_changed
          user.save
          expect(user.errors).to_not be_empty
          expect(user).to be_changed
        end
      end
    end

    context "for new resource" do

      let(:user) { User.new(name: "Lindsay Fünke") }

      it "has changes" do
        expect(user).to be_changed
      end

      it "tracks dirty attributes" do
        user.name = "Tobias Fünke"
        expect(user.name_changed?).to be_truthy
        expect(user).to be_changed
        user.save
        expect(user).to_not be_changed
      end
    end
  end
end
#
