$:.unshift File.join(File.dirname(__FILE__), *%w[.. lib])

require 'rspec'
require 'rspec/its'
require 'simplecov'
require 'faraday_middleware'
require 'active_service'

SimpleCov.start

# Requires everything in 'spec/support'
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

# Remove ActiveModel deprecation message
I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.include ActiveService::Testing::Macros::ModelMacros
  config.include ActiveService::Testing::Macros::RequestMacros
  
  config.before :each do
    @spawned_models = []
  end

  config.after :each do
    @spawned_models.each do |model|
      Object.instance_eval { remove_const model } if Object.const_defined?(model)
    end
  end  
end
