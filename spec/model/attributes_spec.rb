# encoding: utf-8
require File.join(File.dirname(__FILE__), "../spec_helper.rb")

describe ActiveService::Model::Attributes do
  context "mapping data to Ruby objects" do
    before do 
      spawn_model "User" do
        attribute :fullname
      end
    end

    it "handles new resource" do
      @new_user = User.new(:fullname => "Tobias Fünke")
      expect(@new_user.fullname).to eq "Tobias Fünke"
    end

    it "accepts new resource with strings as hash keys" do
      @new_user = User.new('fullname' => "Tobias Fünke")
      expect(@new_user.fullname).to eq "Tobias Fünke"
    end

    it "handles respond_to for getter" do
      @new_user = User.new(:fullname => 'Mayonegg')
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.fullname }.not_to raise_error()      
    end

    it "handles respond_to for setter" do
      @new_user = User.new(:fullname => 'Mayonegg')
      expect { @new_user.unknown_method_for_a_user }.to raise_error(NoMethodError)
      expect { @new_user.fullname }.not_to raise_error()            
    end

    it "handles respond_to for query" do
      @new_user = User.new
      expect(@new_user).to respond_to :fullname?
    end

    it "handles has_attribute?" do
      expect(User).not_to have_attribute(:unknown_method_for_a_user)
      expect(User).to have_attribute(:fullname)
    end

    it "handles [] for getter" do
      @new_user = User.new(:fullname => 'Mayonegg')
      expect { @new_user[:unknown_method_for_a_user] }.to raise_error(ActiveAttr::UnknownAttributeError)
      expect(@new_user[:fullname]).to eq 'Mayonegg'
    end

    it "handles get_attribute for getter with dash" do
      User.attribute :'life-span'
      @new_user = User.new(:'life-span' => '3 years')
      expect { @new_user[:unknown_method_for_a_user] }.to raise_error(ActiveAttr::UnknownAttributeError)
      expect(@new_user[:'life-span']).to eq '3 years'
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
    pending
  end
end
