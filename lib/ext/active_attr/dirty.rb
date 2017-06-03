# = ActiveAttr
#
# ActiveAttr provides most of the ActiveModel functionality in ActiveService.
# Here we patch ActiveAttr with dirty tracking on each attribute that's defined.

require 'active_model/dirty'

module ActiveAttr::Dirty
  extend ActiveSupport::Concern
  include ActiveModel::Dirty

  module ClassMethods
    def attribute!(name, options={})
      super(name, options)
      define_method("#{name}=") do |value|
        send("#{name}_will_change!") unless value == read_attribute(name)
        super(value)
      end
    end
  end

  def modified_attributes
    changes.each_with_object({}) do |(attribute, values), modified|
      modified[attribute] = values.last
    end
  end
end
