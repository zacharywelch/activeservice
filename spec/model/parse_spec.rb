# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Parse do
  context "when include_root_in_json is set" do
    before do
      ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! :user => { :id => 1, :name => params(env)[:user][:name] } }
          stub.post("/users/admins") { |env| ok! :user => { :id => 1, :name => params(env)[:user][:name] } }
        end
      end
    end

    context "to true" do
      before do
        spawn_model "User" do
          attribute :name
          include_root_in_json true
          parse_root_in_json true
          custom_post :admins
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = User.new(:name => "Tobias Fünke")
        expect(@new_user.to_params).to eq({ :user => { :id => nil, :name => "Tobias Fünke" } })
      end

      xit "wraps params in the element name in `.create`" do
        @new_user = User.admins(:name => "Tobias Fünke")
        expect(@new_user.name).to eq "Tobias Fünke"
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
        @new_user = User.new(:name => "Tobias Fünke")
        expect(@new_user.to_params).to eq({ :person => { :id => nil, :name => "Tobias Fünke" } })
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
        @new_user = User.new(:name => "Tobias Fünke")
        expect(@new_user.to_params).to eq({ :user => { :id => nil, :name => "Tobias Fünke" } })
      end
    end
  end

  context "when parse_root_in_json is set" do
    context "to true" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.adapter :test do |stub|
            stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
            stub.get("/users") { |env| [200, {}, [{ :user => { :id => 1, :name => "Lindsay Fünke" } }].to_json] }
            stub.get("/users/admins") { |env| [200, {}, [{ :user => { :id => 1, :name => "Lindsay Fünke" } }].to_json] }
            stub.get("/users/1") { |env| [200, {}, { :user => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
            stub.put("/users/1") { |env| [200, {}, { :user => { :id => 1, :name => "Tobias Fünke Jr." } }.to_json] }
          end
        end

        spawn_model "User" do
          uses_api api
          attribute :name    
          custom_get :admins
          parse_root_in_json true
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = User.create(:name => "Lindsay Fünke")
        expect(@new_user.name).to eq "Lindsay Fünke"
      end

      xit "parse the data from the JSON root element after an arbitrary HTTP request" do
        @new_user = User.admins
        expect(@new_user.first.name).to eq "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .all" do
        @users = User.all
        expect(@users.first.name).to eq "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .find" do
        @user = User.find(1)
        expect(@user.name).to eq "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .save" do
        @user = User.find(1)
        @user.name = "Tobias Fünke"
        @user.save
        expect(@user.name).to eq "Tobias Fünke Jr."
      end
    end

    context "to a symbol" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.adapter :test do |stub|
            stub.post("/users") { |env| [200, {}, { :person => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
          end
        end

        spawn_model "User" do 
          uses_api api
          attribute :name
          parse_root_in_json :person
        end
      end

      it "parse the data with the symbol" do
        @new_user = User.create(:name => "Lindsay Fünke")
        expect(@new_user.name).to eq "Lindsay Fünke"
      end
    end

    context "in the parent class" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.adapter :test do |stub|
            stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
            stub.get("/users") { |env| [200, {}, { :users => [ { :id => 1, :name => "Lindsay Fünke" } ] }.to_json] }
          end
        end

        spawn_model "Model" do
          uses_api api
          parse_root_in_json true, format: :active_model_serializers
        end

        class User < Model
          attribute :name
          collection_path "/users"
        end

        @spawned_models << :User
      end

      it "parse the data with the symbol" do
        @new_user = User.create(:name => "Lindsay Fünke")
        expect(@new_user.name).to eq "Lindsay Fünke"
      end

      it "parses the collection of data" do
        @users = User.all
        expect(@users.first.name).to eq "Lindsay Fünke"
      end
    end

    context "to true with :format => :active_model_serializers" do
      before do
        api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
          builder.adapter :test do |stub|
            stub.post("/users") { |env| [200, {}, { :user => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
            stub.get("/users") { |env| [200, {}, { :users => [ { :id => 1, :name => "Lindsay Fünke" } ] }.to_json] }
            stub.get("/users/admins") { |env| [200, {}, { :users => [ { :id => 1, :name => "Lindsay Fünke" } ] }.to_json] }
            stub.get("/users/1") { |env| [200, {}, { :user => { :id => 1, :name => "Lindsay Fünke" } }.to_json] }
            stub.put("/users/1") { |env| [200, {}, { :user => { :id => 1, :name => "Tobias Fünke Jr." } }.to_json] }
          end
        end

        spawn_model "User" do
          uses_api api
          attribute :name
          parse_root_in_json true, :format => :active_model_serializers
          custom_get :admins
        end
      end

      it "parse the data from the JSON root element after .create" do
        @new_user = User.create(:name => "Lindsay Fünke")
        expect(@new_user.name).to eq "Lindsay Fünke"
      end

      xit "parse the data from the JSON root element after an arbitrary HTTP request" do
        @users = User.admins
        @users.first.name.should == "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .all" do
        @users = User.all
        expect(@users.first.name).to eq "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .find" do
        @user = User.find(1)
        expect(@user.name).to eq "Lindsay Fünke"
      end

      it "parse the data from the JSON root element after .save" do
        @user = User.find(1)
        @user.name = "Tobias Fünke"
        @user.save
        expect(@user.name).to eq "Tobias Fünke Jr."
      end
    end
  end

  context "when to_params is set" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.adapter :test do |stub|
          stub.post("/users") { |env| ok! :id => 1, :name => params(env)['name'] }
          # stub.post("/users") { |env| ok! :id => 1, :name => "Lindsay Fünke" }          
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
        def to_params
          { :name => "Lindsay Fünke" }
        end
      end
    end

    xit "changes the request parameters for one-line resource creation" do
      @user = User.create(:name => "Tobias Fünke")
      expect(@user.name).to eq "Lindsay Fünke"
    end

    xit "changes the request parameters for Model.new + #save" do
      @user = User.new(:name => "Tobias Fünke")
      @user.save
      expect(@user.name).to eq "Lindsay Fünke"
    end
  end

  context "when parse_root_in_json set json_api to true" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.adapter :test do |stub|
          stub.get("/users") { |env| [200, {},  { :users => [{ :id => 1, :name => "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/admins") { |env| [200, {}, { :users => [{ :id => 1, :name => "Lindsay Fünke" }] }.to_json] }
          stub.get("/users/1") { |env| [200, {}, { :users => [{ :id => 1, :name => "Lindsay Fünke" }] }.to_json] }
          stub.post("/users") { |env| [200, {}, { :users => [{ :name => "Lindsay Fünke" }] }.to_json] }
          stub.put("/users/1") { |env| [200, {}, { :users => [{ :id => 1, :name => "Tobias Fünke Jr." }] }.to_json] }
        end
      end

      spawn_model "User" do
        uses_api api 
        parse_root_in_json true, :format => :json_api
        include_root_in_json true
        custom_get :admins
        attribute :name
      end
    end

    xit "parse the data from the JSON root element after .create" do
      @new_user = User.create(:name => "Lindsay Fünke")
      expect(@new_user.name).to eq "Lindsay Fünke"
    end

    xit "parse the data from the JSON root element after an arbitrary HTTP request" do
      @new_user = User.admins
      @new_user.first.name.should == "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after .all" do
      @users = User.all
      expect(@users.first.name).to eq "Lindsay Fünke"
    end

    it "parse the data from the JSON root element after .find" do
      @user = User.find(1)
      expect(@user.name).to eq "Lindsay Fünke"
    end

    xit "parse the data from the JSON root element after .save" do
      @user = User.find(1)
      @user.name = "Tobias Fünke"
      @user.save
      expect(@user.name).to eq "Tobias Fünke Jr."
    end

    xit "parse the data from the JSON root element after new/save" do
      @user = User.new
      @user.name = "Lindsay Fünke (before save)"
      @user.save
      expect(@user.name).to eq "Lindsay Fünke"
    end
  end

  context "when include_root_in_json set json_api" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.adapter :test do |stub|
          stub.post("/users") { |env| [200, {}, { :users => [{ :id => 1, :name => params(env)[:users][:name] }] }.to_json] }
        end
      end
    end

    context "to true" do
      before do
        spawn_model "User" do
          uses_api api
          include_root_in_json true
          parse_root_in_json true, format: :json_api
          custom_post :admins
          attribute :name
        end
      end

      it "wraps params in the element name in `to_params`" do
        @new_user = User.new(:name => "Tobias Fünke")
        expect(@new_user.to_params).to eq({ :users => [{ :id => nil, :name => "Tobias Fünke" }] })
      end

      it "wraps params in the element name in `.where`" do
        @new_user = User.where(:name => "Tobias Fünke").build
        expect(@new_user.name).to eq"Tobias Fünke"
      end
    end
  end

  context 'when send_only_modified_attributes is set' do
    pending
  end
end
