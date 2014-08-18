require 'active_model'
require 'active_service/model/http'
require 'active_service/model/attributes'
require 'active_service/model/attributes'
require 'active_service/model/relation'
require 'active_service/model/orm'
require 'active_service/model/parse'
require 'active_service/model/associations'
require 'active_service/model/introspection'
require 'active_service/model/paths'
require 'active_service/model/nested_attributes'
require 'active_service/model/serialization'

module ActiveService
  module Model
    extend ActiveSupport::Concern

    # ActiveAttr modules 
    include ActiveAttr::BasicModel
    include ActiveAttr::BlockInitialization
    include ActiveAttr::Logger
    include ActiveAttr::MassAssignment
    include ActiveAttr::AttributeDefaults
    include ActiveAttr::QueryAttributes
    include ActiveAttr::TypecastedAttributes

    # ActiveService modules
    include ActiveService::Model::Attributes
    include ActiveService::Model::ORM
    include ActiveService::Model::HTTP
    include ActiveService::Model::Parse
    include ActiveService::Model::Introspection
    include ActiveService::Model::Paths
    include ActiveService::Model::Associations
    include ActiveService::Model::NestedAttributes
    include ActiveService::Model::Serialization

    included do
      # Assign the default API
      use_api ActiveService::API.default_api
      method_for :create, :post
      method_for :update, :put
      method_for :find, :get
      method_for :destroy, :delete
      method_for :new, :get

      # Define the default primary key
      primary_key :id

      # Define an id attribute (handled by primary_key?)
      attribute :id

      # Define the default collection parser
      collection_parser ActiveService::Collection
            
      # Include ActiveModel naming methods
      extend ActiveModel::Translation
      
      # Configure ActiveModel callbacks
      extend ActiveModel::Callbacks
      define_model_callbacks :save, :create, :update, :destroy
      before_save { !destroyed? && valid? }
    end
  end
end