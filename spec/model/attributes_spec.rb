# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes do
  context "mapping data to Ruby objects" do
    before do 
      spawn_model "User" do
        attribute :name
        attribute :'life-span'
        attribute :admin, default: false
      end
    end

    it "handles new resource" do
      @new_user = User.new(:name => "Tobias Fünke")
      expect(@new_user.name).to eq "Tobias Fünke"
    end

    it "accepts new resource with strings as hash keys" do
      @new_user = User.new('name' => "Tobias Fünke")
      expect(@new_user.name).to eq "Tobias Fünke"
    end

    it "handles respond_to for getter" do
      @new_user = User.new(:name => 'Mayonegg')
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.name }.not_to raise_error()      
    end

    it "handles respond_to for setter" do
      @new_user = User.new(:name => 'Mayonegg')
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.name }.not_to raise_error()            
    end

    it "handles respond_to for query" do
      @new_user = User.new
      expect(@new_user).to respond_to :name?
    end

    it "handles has_attribute? for getter" do
      @new_user = User.new(:name => 'Mayonegg')
      expect(@new_user).not_to have_attribute(:unknown_method_for_a_user)
      expect(@new_user).to have_attribute(:name)      
    end

    it "handles get_attribute for getter" do
      @new_user = User.new(:name => 'Mayonegg')
      expect(@new_user.get_attribute(:unknown_method_for_a_user)).to be_nil
      expect(@new_user.get_attribute(:name)).to eq 'Mayonegg'
    end

    it "handles get_attribute for getter with dash" do
      @new_user = User.new(:'life-span' => '3 years')
      expect(@new_user.get_attribute(:unknown_method_for_a_user)).to be_nil
      expect(@new_user.get_attribute(:'life-span')).to eq '3 years'
    end

    it "applies defaults" do
      @new_user = User.new
      expect(@new_user.admin).to be_falsey
    end
  end

  context "assigning new resource data" do
    before do
      spawn_model "User" do
        attribute :active
      end
      @user = User.new(:active => false)
    end

    it "handles data update through #assign_attributes" do
      @user.assign_attributes :active => true
      expect(@user).to be_active
    end
  end

  context "checking resource equality" do
    before do
      api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
        builder.request :url_encoded
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| ok! :id => 1, :name => "Lindsay Fünke" }
          stub.get("/users/2") { |env| ok! :id => 1, :name => "Tobias Fünke" }
          stub.get("/admins/1") { |env| ok! :id => 1, :name => "Lindsay Fünke" }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name
      end
      
      spawn_model "Admin" do
        uses_api api
        attribute :name
      end
    end

    let(:user) { User.find(1) }

    it "returns true for the exact same object" do
      expect(user).to eq user
    end

    it "returns true for the same resource via find" do
      expect(user).to eq User.find(1)
    end

    it "returns true for the same class with identical data" do
      expect(user).to eq User.new(:id => 1, :name => "Lindsay Fünke")
    end

    it "returns true for a different resource with the same data" do
      expect(user).to eq Admin.find(1)
    end

    it "returns false for the same class with different data" do
      expect(user).to_not eq User.new(:id => 2, :name => "Tobias Fünke")
    end

    it "returns false for a non-resource with the same data" do
      fake_user = double(:data => { :id => 1, :name => "Lindsay Fünke" })
      expect(user).to_not eq fake_user
    end

    it "delegates eql? to ==" do
      other = Object.new
      expect(user).to receive(:==).with(other).and_return(true)
      expect(user.eql?(other)).to be_truthy
    end

    it "treats equal resources as equal for Array#uniq" do
      user2 = User.find(1)
      expect([user, user2].uniq).to eq [user]
    end

    it "treats equal resources as equal for hash keys" do
      hash = { user => true }
      hash[User.find(1)] = false
      expect(hash.size).to eql 1
      expect(hash).to eq({ user => false })
    end
  end

  context "attributes are different than source" do
    before do
      api = ActiveService::API.new :url => "https://api.example.com" do |builder|
        builder.use ActiveService::Middleware::ParseJSON
        builder.adapter :test do |stub|
          stub.get("/users/1") { |env| ok! :id => 1, :UserName => "Tobias Fünke" }
          stub.get("/users?UserName=foo") { |env| ok! [{ :id => 3, :UserName => "foo" }] }
        end
      end

      spawn_model "User" do
        uses_api api
        attribute :name, :source => 'UserName'
      end
    end

    let(:user) { User.find(1) }

    it "maps source fields to attributes" do
      expect(user.name).to eq "Tobias Fünke"
      expect(user).not_to respond_to :UserName 
    end
  end
end
