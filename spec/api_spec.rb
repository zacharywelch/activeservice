# encoding: utf-8
require 'spec_helper.rb'

describe ActiveService::API do
  subject { ActiveService::API.new }

  context "initialization" do
    describe ".setup" do
      it "creates a default connection" do
        ActiveService::API.setup :url => "https://api.example.com"
        expect(ActiveService::API.default_api.base_uri).to eq("https://api.example.com")
      end
    end

    describe "#setup" do
      context "when using :url option" do
        before { subject.setup :url => "https://api.example.com" }
        its(:base_uri) { should == "https://api.example.com" }
      end

      context "when using the legacy :base_uri option" do
        before { subject.setup :base_uri => "https://api.example.com" }
        its(:base_uri) { should == "https://api.example.com" }
      end

      context "when setting custom middleware" do
        before do
          class Foo; end;
          class Bar; end;

          subject.setup :url => "https://api.example.com" do |connection|
            connection.use Foo
            connection.use Bar
          end
        end

        specify { expect(subject.connection.builder.handlers).to eq([Foo, Bar]) }
      end

      context "when setting custom options" do
        before { subject.setup :foo => { :bar => "baz" }, :url => "https://api.example.com" }
        its(:options) { should == { :foo => { :bar => "baz" }, :url => "https://api.example.com" } }
      end
    end

    describe "#request" do
      context "making HTTP requests" do
        let(:response) { subject.request(:_method => :get, :_path => "/foo").body }
        before do
          subject.setup :url => "https://api.example.com" do |builder|
            builder.adapter(:test) { |stub| stub.get("/foo") { |env| [200, {}, "Foo, it is."] } }
          end
        end
        specify { expect(response).to eq("Foo, it is.") }
      end

      context "making HTTP requests while specifying custom HTTP headers" do
        let(:response) { subject.request(:_method => :get, :_path => "/foo", :_headers => { "X-Page" => 2 }).body }
        before do
          subject.setup :url => "https://api.example.com" do |builder|
            builder.adapter(:test) { |stub| stub.get("/foo") { |env| [200, {}, "Foo, it is page #{env[:request_headers]["X-Page"]}."] } }
          end
        end
        specify { expect(response).to eq("Foo, it is page 2.") }
      end

      context "making HTTP requests while specifying custom request options" do
        let(:response) { subject.request(:_method => :get, :_path => "/foo", _timeout: 2).body }
        before do
          subject.setup :url => "https://api.example.com" do |builder|
            builder.adapter(:test) { |stub| stub.get("/foo") { |env| [200, {}, "Foo, it has timeout #{env[:request]["timeout"]}."] } }
          end
        end
        specify { expect(response).to eq("Foo, it has timeout 2.") }
      end

      context "parsing a request with the middleware json parser" do
        let(:response) { subject.request(:_method => :get, :_path => "users/1").body }
        before do
          subject.setup :url => "https://api.example.com" do |builder|
            builder.use ActiveService::Middleware::ParseJSON
            builder.adapter :test do |stub|
              stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Foo Bar" }.to_json] }
            end
          end
        end
        specify do
          expect(response).to eq({ :id => 1, :name => "Foo Bar" })
        end
      end

      context "parsing a request with a custom parser" do
        let(:response) { subject.request(:_method => :get, :_path => "users/1").body }
        before do
          class CustomParser < Faraday::Response::Middleware
            def on_complete(env)
              json = JSON.parse(env[:body], symbolize_names: true)
              metadata = json.delete(:metadata) || {}
              env[:body] = {
                :data => json,
                :metadata => metadata,
              }
            end
          end

          subject.setup :url => "https://api.example.com" do |builder|
            builder.use CustomParser
            builder.adapter :test do |stub|
              stub.get("/users/1") { |env| [200, {}, { id: 1, name: "Foo" }.to_json] }
            end
          end
        end

        specify do
          expect(response[:data]).to eq({ id: 1, name: "Foo" })
          expect(response[:metadata]).to eq({})
        end
      end
    end
  end
end
