# encoding: utf-8
require 'spec_helper'

describe ActiveService::Model do
  before do
    api = ActiveService::API.new :url => "https://api.example.com" do |connection|
      connection.use ActiveService::Middleware::ParseJSON
      connection.adapter :test do |stub|
        stub.get("/users/1") { |env| ok! :id => 1, :name => "Tobias Fünke" }
        stub.get("/users/1/comments") { |env| ok! [{ :id => 4, :body => "They're having a FIRESALE?", :user_id => 1 }] }
      end
    end

    spawn_model "User" do
      uses_api api 
      attribute :name
      has_many :comments
    end

    spawn_model "Comment" do
      uses_api api
      attribute :body
      attribute :user_id
      belongs_to :user
    end
  end
  subject { User.find(1) }

  describe :has_key? do
    it { is_expected.to_not have_key(:unknown_method_for_a_user) }
    it { is_expected.to_not have_key(:unknown_method_for_a_user) }
    it { is_expected.to have_key(:name) }
    it { is_expected.to have_key(:comments) }
  end

  describe :[] do
    it { is_expected.to_not have_key(:unknown_method_for_a_user) }
    specify { expect(subject[:name]).to eq "Tobias Fünke" }
    specify { expect(subject[:comments].first.body).to eq "They're having a FIRESALE?" }
  end

  describe :singularized_resource_name do
    specify { expect(subject.singularized_resource_name).to eq "user" }
  end
end
