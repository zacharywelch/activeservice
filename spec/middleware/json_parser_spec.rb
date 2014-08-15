# encoding: utf-8
require "spec_helper"

describe ActiveService::Middleware::ParseJSON do
  subject { described_class.new }
  let(:body_with_valid_json) { "{\"id\": 1, \"name\": \"Tobias Fünke\"}" }
  let(:body_with_malformed_json) { "wut." }
  let(:body_with_invalid_json) { "true" }
  let(:empty_body) { '' }
  let(:nil_body) { nil }

  it "parses :body key as json in the env hash" do
    env = { :body => body_with_valid_json }
    subject.on_complete(env)
    env[:body].tap do |json|
      expect(json).to eq({ :id => 1, :name => "Tobias Fünke" })
    end
  end

  it 'ensures that malformed JSON throws an exception' do
    env = { :body => body_with_malformed_json }
    expect { subject.on_complete(env) }.to raise_error(ActiveService::Errors::ParserError)
  end

  it 'ensures that invalid JSON throws an exception' do
    env = { :body => body_with_invalid_json }
    expect { subject.on_complete(env) }.to raise_error(ActiveService::Errors::ParserError)
  end

  it 'ensures that a nil response returns an empty hash' do
    env = { :body => nil_body }
    expect(subject.on_complete(env)).to eq({})
  end

  it 'ensures that an empty response returns an empty hash' do
    env = { :body => empty_body }
    expect(subject.on_complete(env)).to eq({})
  end
end
