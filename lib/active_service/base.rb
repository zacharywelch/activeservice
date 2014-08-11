require 'active_service/model'

module ActiveService
  # ActiveService::Base is the main class for mapping web services to models.
  #
  # For an outline of Active Service's features, see its +README+.
  #
  # @example
  #   class Person < ActiveService::Base
  #     self.base_uri = "https://api.people.com"
  #     attribute :name
  #   end
  #
  #   @person = Person.new(:name => "Foo")
  #   @person.save
  class Base
    include ActiveService::Model
  end
end