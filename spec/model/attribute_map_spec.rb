# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes::AttributeMap do
  describe "#new" do
    context "when source and target are the same" do
      before do
        spawn_model "User" do
          attribute :name
        end
      end

      let(:definitions) { User.attributes.values }      
      subject(:map) { ActiveService::Model::Attributes::AttributeMap.new(definitions) }

      its(:attributes) { should == { :id => "id", :name => "name" } }
      its(:by_source) { should == { "id" => :id, "name" => :name } }
    end

    context "when source and target are different" do
      before do
        spawn_model "User" do
          attribute :name, :source => "UserName"
        end
      end

      let(:definitions) { User.attributes.values }      
      subject(:map) { ActiveService::Model::Attributes::AttributeMap.new(definitions) }

      its(:attributes) { should == { :id => "id", :name => "UserName" } }
      its(:by_source) { should == { "id" => :id, "UserName" => :name } }
    end
  end

  describe :by_source do
    before do
      spawn_model "User" do
        attribute :name, :source => "UserName"
      end
    end    

    it "returns a hash with source names as keys and attributes as values" do
      expect(User.attribute_map.by_source).to eq({ "id" => :id, "UserName" => :name })
    end
  end

  describe :map do
    before do
      spawn_model "User" do
        attribute :name, :source => "UserName"
      end
    end

    it "maps source names to attributes by default" do
      hash = { "id" => 1, "UserName" => "foo" }
      expect(User.attribute_map.map(hash)).to eq({ id: 1, name: "foo" })
    end

    it "maps attributes to source names with :to => source option" do
      hash = { :id => 1, :name => "foo" }
      expect(User.attribute_map.map(hash, :to => :source)).to eq({ "id" => 1, "UserName" => "foo" })
    end    
  end
end
