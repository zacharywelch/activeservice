require 'client/persistence'

# = ActiveService 
#
# ActiveService combines the ActiveModel features of ActiveAttr with a 
# persistence mechanism using Typhoeus.
module ActiveAttr
  module Model
    include Persistence
  end
end