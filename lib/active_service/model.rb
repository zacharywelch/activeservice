require 'active_attr'
require 'active_service/persistence'

# = ActiveService 
#
# ActiveService combines the ActiveModel features of ActiveAttr with a 
# persistence mechanism using Typhoeus.

module ActiveAttr::Model
  include Persistence
end

module ActiveService
  include ActiveAttr
end