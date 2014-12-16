require 'spec_helper'

describe ActiveService::Errors do
  api = ActiveService::API.setup :url => "https://api.example.com" do |builder|
    builder.use ActiveService::Middleware::ParseJSON
    builder.adapter :test do |stub|
      stub.get("/BadRequest") { |env| [400, {}, { :errors => "BadRequest" }.to_json] }
      stub.get("/UnauthorizedAccess") { |env| [401, {}, { :errors => "UnauthorizedAccess" }.to_json] }
      stub.get("/ResourceNotFound") { |env| [404, {}, { :errors => "ResourceNotFound" }.to_json] }
      stub.get("/TimeoutError") { |env| [408, {}, { :errors => "TimeoutError" }.to_json] }
      stub.get("/ResourceInvalid") { |env| [422, {}, { :errors => "ResourceInvalid" }.to_json] }
      stub.get("/ClientError") { |env| [467, {}, { :errors => "ClientError" }.to_json] }
      stub.get("/ServerError") { |env| [567, {}, { :errors => "ServerError" }.to_json] }
    end
  end
  context 'when a BadRequest error is raised' do
    it "should raise a BadRequest error" do
      expect {
        error = api.request(:_method => :get, :_path => "BadRequest")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::BadRequest)
        error.body.should include(:errors => "BadRequest")
      }
    end
  end
    context 'when a UnauthorizedAccess error is raised' do
    it "should raise a UnauthorizedAccess error" do
      expect {
        error = api.request(:_method => :get, :_path => "UnauthorizedAccess")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::UnauthorizedAccess)
        error.body.should include(:errors => "UnauthorizedAccess")
      }
    end
  end
    context 'when a ResourceNotFound error is raised' do
    it "should raise a ResourceNotFound error" do
      expect {
        error = api.request(:_method => :get, :_path => "ResourceNotFound")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::ResourceNotFound)
        error.body.should include(:errors => "ResourceNotFound")
      }
    end
  end
    context 'when a TimeoutError error is raised' do
    it "should raise a TimeoutError error" do
      expect {
        error = api.request(:_method => :get, :_path => "TimeoutError")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::ClientError)
        error.body.should include(:errors => "TimeoutError")
      }
    end
  end
    context 'when a ResourceInvalid error is raised' do
    it "should raise a ResourceInvalid error" do
      expect {
        error = api.request(:_method => :get, :_path => "ResourceInvalid")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::ResourceInvalid)
        error.body.should include(:errors => "ResourceInvalid")
      }
    end
  end
    context 'when a ClientError error is raised' do
    it "should raise a ClientError error" do
      expect {
        error = api.request(:_method => :get, :_path => "ClientError")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::ClientError)
        error.body.should include(:errors => "ClientError")
      }
    end
  end
    context 'when a ServerError error is raised' do
    it "should raise a ServerError error" do
      expect {
        error = api.request(:_method => :get, :_path => "ServerError")
      }.to raise_error { |error|
        error.should be_a(ActiveService::Errors::ServerError)
        error.body.should include(:errors => "ServerError")
      }
    end
  end
end