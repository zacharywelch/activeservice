require 'active_support/concern'
require 'active_attr/attributes'
require 'active_model'
require 'client/crud'

module Persistence
  extend  ActiveSupport::Concern
  extend  ActiveModel::Callbacks
  include Persistence::CRUD  

  included do
    attribute :id
    
    # Define callbacks matching the life cycle of Active Record objects 
    define_model_callbacks :save, :create, :update, :destroy

    before_save { !destroyed? && valid? }
    after_destroy { @destroyed = true }
  end

  def persisted?
    id.present? && !destroyed?
  end

  def new?
    !(persisted? || destroyed?)
  end

  alias :new_record? :new?

  def destroyed?
    @destroyed || false
  end
end