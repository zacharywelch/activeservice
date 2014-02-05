require 'active_support/concern'
require 'active_attr/attributes'
require 'active_model'
require 'client/crud'

# = Persistence
# 
# Persistence facilitates the storage of ActiveAttr(ActiveModel) models to a 
# remote data store using Typhoeus. Where ActiveRecord runs SQL statements 
# against a database, Persistence runs HTTP requests against a web service api.
#
# ActiveService uses an interface similar to ActiveRecord for querying an 
# object's state (new?, destroyed?, etc.) and interacting w/ the remote service.
module Persistence
  extend  ActiveSupport::Concern
  extend  ActiveModel::Callbacks
  include Persistence::CRUD  

  included do
    attribute :id
    
    # Define callbacks matching the life cycle of Active Record objects 
    # For documentation on the use of callbacks see the Active Record 
    # documentation at: 
    # http://edgeguides.rubyonrails.org/active_record_callbacks.html
    define_model_callbacks :save, :create, :update, :destroy

    # Before saving make sure the object isn't destroyed and it 
    # passes all validations 
    before_save { !destroyed? && valid? }
    after_destroy { @destroyed = true }
  end

  # Returns true if the record is persisted, i.e. it's not a new record and it 
  # was not destroyed, otherwise returns false.
  def persisted?
    id.present? && !destroyed?
  end

  # Returns true if this object hasn't been saved yet -- that is, a record
  # for the object doesn't exist in the data store yet; otherwise, returns false.
  def new?
    !(persisted? || destroyed?)
  end

  alias :new_record? :new?

  # Returns true if this object has been destroyed, otherwise returns false.
  def destroyed?
    @destroyed || false
  end
end