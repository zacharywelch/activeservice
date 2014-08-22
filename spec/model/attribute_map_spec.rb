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
end
