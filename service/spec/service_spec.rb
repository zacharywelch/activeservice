ENV['SINATRA_ENV'] = 'test'

require File.dirname(__FILE__) + '/../service'
require 'rspec'
require 'rack/test'

RSpec.configure do |config|
  config.include Rack::Test::Methods
end

def app 
  Sinatra::Application
end

describe "service" do
  before(:each) do
    User.delete_all
  end

  describe "GET on /api/v1/users" do
    before { @user = User.create(name: "foo", email: "foo@bar.com") }

    it "should return an array of users" do
      get "/api/v1/users"
      last_response.should be_ok
      users = JSON.parse(last_response.body)
      users.should_not be_empty
    end

    # it "should include our user" do
    #   get "/api/v1/users"
    #   last_response.should be_ok
    #   users = JSON.parse(last_response.body)
    #   users.should include(@user.to_json) }
    # end
  end

  describe "GET on /api/v1/users/:id" do
    before { @user = User.create(name: "foo", email: "foo@bar.com") }
    let(:id) { @user.id }

    it "should return a user with an id" do
      get "/api/v1/users/#{id}"
      last_response.should be_ok
      attributes = JSON.parse(last_response.body)
      attributes["email"].should == @user.email
    end

    it "should return a 404 for a user that doesn't exist" do
      get '/api/v1/users/0'
      last_response.status.should == 404
    end
  end

  describe "POST on /api/v1/users" do
    it "should create a user" do
      post '/api/v1/users', { name: "bill", email: "bill@example.com" }.to_json
      last_response.should be_ok
      # get '/api/v1/users/bill'
      attributes = JSON.parse(last_response.body)
      attributes["name"].should  == "bill"
      attributes["email"].should == "bill@example.com"
    end
  end

  describe "PUT on /api/v1/users/:id" do
    it "should update a user" do
      user = User.create(name: "bob", email: "bob@example.com")
      put "/api/v1/users/#{user.id}", { email: "bar@foo.com" }.to_json
      last_response.should be_ok
      get "/api/v1/users/#{user.id}"
      attributes = JSON.parse(last_response.body)
      attributes["email"].should == "bar@foo.com"
    end
  end

  describe "DELETE on /api/v1/users/:id" do
    before { @user = User.create(name: "francis", email: "no spam") }
    let(:id) { @user.id }
    it "should delete a user" do
      delete "/api/v1/users/#{id}"
      last_response.should be_ok
      get "/api/v1/users/#{id}"
      last_response.status.should == 404
    end
  end
end