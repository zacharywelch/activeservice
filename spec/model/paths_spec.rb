# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Paths do
  context "building request paths" do
    context "simple model" do
      before do
        spawn_model "User" do 
          attribute :id
          attribute :name
        end
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          expect(User.build_request_path(:id => "foo")).to eq "users/foo"
          expect(User.build_request_path(:id => nil)).to eq "users"
          expect(User.build_request_path).to eq "users"
        end

        it "builds paths with custom collection path" do
          User.collection_path "/hodors"
          expect(User.build_request_path).to eq "/hodors"
          expect(User.build_request_path(:id => "foo")).to eq "/hodors/foo"
        end

        it "builds paths with custom relative collection path" do
          User.collection_path "hodors"
          expect(User.build_request_path(:id => "foo")).to eq "hodors/foo"
          expect(User.build_request_path).to eq "hodors"
        end

        it "builds paths with custom collection path with multiple variables" do
          User.collection_path "/organizations/:organization_id/hodors"

          expect(User.build_request_path(:id => "foo", :_organization_id => "acme")).to eq "/organizations/acme/hodors/foo"
          expect(User.build_request_path(:_organization_id => "acme")).to eq "/organizations/acme/hodors"

          expect(User.build_request_path(:id => "foo", :organization_id => "acme")).to eq "/organizations/acme/hodors/foo"
          expect(User.build_request_path(:organization_id => "acme")).to eq "/organizations/acme/hodors"
        end

        it "builds paths with custom relative collection path with multiple variables" do
          User.collection_path "organizations/:organization_id/hodors"

          expect(User.build_request_path(:id => "foo", :_organization_id => "acme")).to eq "organizations/acme/hodors/foo"
          expect(User.build_request_path(:_organization_id => "acme")).to eq "organizations/acme/hodors"

          expect(User.build_request_path(:id => "foo", :organization_id => "acme")).to eq "organizations/acme/hodors/foo"
          expect(User.build_request_path(:organization_id => "acme")).to eq "organizations/acme/hodors"
        end

        it "builds paths with custom item path" do
          User.element_path "/hodors/:id"
          expect(User.build_request_path(:id => "foo")).to eq "/hodors/foo"
          expect(User.build_request_path).to eq "users"
        end

        it "builds paths with custom relative item path" do
          User.element_path "hodors/:id"
          expect(User.build_request_path(:id => "foo")).to eq "hodors/foo"
          expect(User.build_request_path).to eq "users"
        end

        it "raises exceptions when building a path without required custom variables" do
          User.collection_path "/organizations/:organization_id/hodors"
          expect { User.build_request_path(:id => "foo") }.to raise_error(ActiveService::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/hodors/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "simple model with multiple words" do
      before do
        spawn_model "AdminUser" do
          attribute :id          
        end
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          expect(AdminUser.build_request_path(:id => "foo")).to eq "admin_users/foo"
          expect(AdminUser.build_request_path).to eq "admin_users"
        end

        it "builds paths with custom collection path" do
          AdminUser.collection_path "/users"
          expect(AdminUser.build_request_path(:id => "foo")).to eq "/users/foo"
          expect(AdminUser.build_request_path).to eq "/users"
        end

        it "builds paths with custom relative collection path" do
          AdminUser.collection_path "users"
          expect(AdminUser.build_request_path(:id => "foo")).to eq "users/foo"
          expect(AdminUser.build_request_path).to eq "users"
        end

        it "builds paths with custom collection path with multiple variables" do
          AdminUser.collection_path "/organizations/:organization_id/users"
          expect(AdminUser.build_request_path(:id => "foo", :_organization_id => "acme")).to eq "/organizations/acme/users/foo"
          expect(AdminUser.build_request_path(:_organization_id => "acme")).to eq "/organizations/acme/users"
        end

        it "builds paths with custom relative collection path with multiple variables" do
          AdminUser.collection_path "organizations/:organization_id/users"
          expect(AdminUser.build_request_path(:id => "foo", :_organization_id => "acme")).to eq "organizations/acme/users/foo"
          expect(AdminUser.build_request_path(:_organization_id => "acme")).to eq "organizations/acme/users"
        end

        it "builds paths with custom item path" do
          AdminUser.element_path "/users/:id"
          expect(AdminUser.build_request_path(:id => "foo")).to eq "/users/foo"
          expect(AdminUser.build_request_path).to eq "admin_users"
        end

        it "builds paths with custom relative item path" do
          AdminUser.element_path "users/:id"
          expect(AdminUser.build_request_path(:id => "foo")).to eq "users/foo"
          expect(AdminUser.build_request_path).to eq "admin_users"
        end

        it "raises exceptions when building a path without required custom variables" do
          AdminUser.collection_path "/organizations/:organization_id/users"
          expect { AdminUser.build_request_path(:id => "foo") }.to raise_error(ActiveService::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `/organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end

        it "raises exceptions when building a relative path without required custom variables" do
          AdminUser.collection_path "organizations/:organization_id/users"
          expect { AdminUser.build_request_path(:id => "foo") }.to raise_error(ActiveService::Errors::PathError, "Missing :_organization_id parameter to build the request path. Path is `organizations/:organization_id/users/:id`. Parameters are `{:id=>\"foo\"}`.")
        end
      end
    end

    context "children model" do
      pending
    end

    context "nested model" do
      before do
        spawn_model "User"
      end

      describe "#build_request_path" do
        it "builds paths with defaults" do
          expect(User.build_request_path(:id => "foo")).to eq "users/foo"
          expect(User.build_request_path).to eq "users"
        end
      end
    end

    context "custom primary key" do
      before do
        spawn_model "User" do
          primary_key "UserId"
          element_path "users/:UserId"
        end

        spawn_model "Customer" do
          primary_key :customer_id
          element_path "customers/:id"
        end
      end

      describe "#build_request_path" do
        it "uses the correct primary key attribute" do
          expect(User.build_request_path(:UserId => "foo")).to eq "users/foo"
          expect(User.build_request_path(:id => "foo")).to eq "users"
        end

        it "replaces :id with the appropriate primary key" do
          expect(Customer.build_request_path(:customer_id => "joe")).to eq "customers/joe"
          expect(Customer.build_request_path(:id => "joe")).to eq "customers"
        end
      end
    end
  end

  context "making subdomain HTTP requests" do
    before do
      ActiveService::API.setup :url => "https://api.example.com/" do |builder|
        builder.adapter :test do |stub|
          stub.get("organizations/2/users") { |env| [200, {}, [{ :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :fullname => "Lindsay Fünke", :organization_id => 2 }].to_json] }
          stub.post("organizations/2/users") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2 }.to_json] }
          stub.put("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2 }.to_json] }
          stub.get("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Tobias Fünke", :organization_id => 2, :active => true }.to_json] }
          stub.delete("organizations/2/users/1") { |env| [200, {}, { :id => 1, :fullname => "Lindsay Fünke", :organization_id => 2, :active => false }.to_json] }
        end
      end

      spawn_model "User" do
        collection_path "organizations/:organization_id/users"
        attribute :id
        attribute :fullname
        attribute :organization_id
        attribute :active
      end
    end

    describe "fetching a resource" do
      pending
    end

    describe "fetching a collection" do
      pending
    end

    describe "handling new resource" do
      pending
    end

    describe "creating resources" do
      pending
    end

    context "updating resources" do
      pending
    end

    context "deleting resources" do
      pending
    end
  end

  context "making path HTTP requests" do
    pending
  end
end
