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
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.use Faraday::Request::UrlEncoded
          builder.use ActiveService::Middleware::ParseJSON          
          builder.adapter :test do |stub|
            stub.get("/users/foo") { |env| ok! :id => 'foo' }
          end
        end

        spawn_model "Model" do 
          uses_api api
          include_root_in_json true
        end

        class User < Model; end
        @spawned_models << :User
      end

      it "builds path using the children model name" do
        expect(User.find('foo').id).to eq 'foo'
        expect(User.find('foo').id).to eq 'foo'
      end
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
      api = ActiveService::API.setup :url => "https://api.example.com/" do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("organizations/2/users") { |env| ok! [{ :id => 1, :name => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :name => "Lindsay Fünke", :organization_id => 2 }] }
          stub.post("organizations/2/users") { |env| ok! :id => 1, :name => "Tobias Fünke", :organization_id => 2 }
          stub.put("organizations/2/users/1") { |env| ok! :id => 1, :name => "Lindsay Fünke", :organization_id => 2 }
          stub.get("organizations/2/users/1") { |env| ok! :id => 1, :name => "Tobias Fünke", :organization_id => 2, :active => true }
          stub.delete("organizations/2/users/1") { |env| ok! :id => 1, :name => "Lindsay Fünke", :organization_id => 2, :active => false }
        end
      end

      spawn_model "User" do
        uses_api api
        collection_path "organizations/:organization_id/users"
        attribute :id
        attribute :name
        attribute :organization_id
        attribute :active
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = User.find(1, :_organization_id => 2)
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
      end

      it "maps a single resource using a scope to a Ruby object" do
        User.scope :for_organization, lambda { |o| where(:organization_id => o) }
        @user = User.for_organization(2).find(1)
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = User.where(:_organization_id => 2)
        expect(@users.length).to be 2
        expect(@users.first.name).to eq "Tobias Fünke"
      end
    end

    describe "handling new resource" do
      it "handles new resource" do
        @new_user = User.new(:name => "Tobias Fünke", :organization_id => 2)
        expect(@new_user.new?).to be_truthy

        @existing_user = User.find(1, :_organization_id => 2)
        expect(@existing_user.new?).to be_falsey
      end
    end

    describe "creating resources" do
      it "handle one-line resource creation" do
        @user = User.create(:name => "Tobias Fünke", :organization_id => 2)
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
      end

      it "handle resource creation through Model.new + #save" do
        @user = User.new(:name => "Tobias Fünke", :organization_id => 2)
        @user.save
        expect(@user.name).to eq "Tobias Fünke"
      end
    end

    context "updating resources" do
      it "handle resource data update without saving it" do
        @user = User.find(1, :_organization_id => 2)
        expect(@user.name).to eq "Tobias Fünke"
        @user.name = "Kittie Sanchez"
        expect(@user.name).to eq "Kittie Sanchez"
      end

      it "handle resource update through #save on an existing resource" do
        @user = User.find(1, :_organization_id => 2)
        @user.name = "Lindsay Fünke"
        @user.save
        expect(@user.name).to eq "Lindsay Fünke"
      end
    end

    context "deleting resources" do
      it "handle resource deletion through the .destroy class method" do
        @user = User.destroy(1, :_organization_id => 2)
        expect(@user.active).to be_falsey
      end

      it "handle resource deletion through #destroy on an existing resource" do
        @user = User.find(1, :_organization_id => 2)
        @user.destroy
        expect(@user.active).to be_falsey
      end
    end  
  end

  context "making path HTTP requests" do
    before do
      api = ActiveService::API.setup :url => "https://example.com/api/" do |builder|
        builder.use Faraday::Request::UrlEncoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/api/organizations/2/users") { |env| ok! [{ :id => 1, :name => "Tobias Fünke", :organization_id => 2 }, { :id => 2, :name => "Lindsay Fünke", :organization_id => 2 }] }
          stub.get("/api/organizations/2/users/1") { |env| ok! :id => 1, :name => "Tobias Fünke", :organization_id => 2, :active => true }
        end
      end

      spawn_model "User" do
        uses_api api
        collection_path "organizations/:organization_id/users"
        attribute :name
        attribute :organization_id
        attribute :active
      end
    end

    describe "fetching a resource" do
      it "maps a single resource to a Ruby object" do
        @user = User.find(1, :organization_id => 2)
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
      end
    end

    describe "fetching a collection" do
      it "maps a collection of resources to an array of Ruby objects" do
        @users = User.where(:organization_id => 2)
        expect(@users.length).to be 2
        expect(@users.first.name).to eq "Tobias Fünke"
      end
    end

    describe "fetching a resource with absolute path" do
      it "maps a single resource to a Ruby object" do
        User.element_path '/api/' + User.element_path
        @user = User.find(1, :organization_id => 2)
        expect(@user.id).to be 1
        expect(@user.name).to eq "Tobias Fünke"
      end
    end

    describe "fetching a collection with absolute path" do
      it "maps a collection of resources to an array of Ruby objects" do
        User.collection_path '/api/' + User.collection_path
        @users = User.where(:organization_id => 2)
        expect(@users.length).to be 2
        expect(@users.first.name).to eq "Tobias Fünke"
      end
    end
  end
end
