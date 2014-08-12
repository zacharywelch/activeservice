# encoding: utf-8
require 'spec_helper'

describe ActiveService::Model do
  before do
    api = ActiveService::API.setup :url => "https://api.example.com" do |connection|
      connection.adapter :test do |stub|
        stub.get("/users/1") { |env| ok! :id => 1, :name => "Tobias Fünke" }
        stub.get("/users/1/comments") { |env| ok! [{ :id => 4, :body => "They're having a FIRESALE?" }] }
      end
    end
  end
  
  describe :has_key? do
    pending
  end

  describe :[] do
    pending
  end
end
