$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_attr'
require 'client/persistence'

I18n.enforce_available_locales = true

# = ActiveService
#
# ActiveService extends ActiveAttr w/ a persistence mechanism
# using Typhoeus 
#
# See the documentation for ActiveAttr and Typhoeus for details on these gems 
#
# For ActiveService examples see README.md
module ActiveAttr
  module Model
    include Persistence
  end
end

# examples 
require 'client/user'
require 'client/security_tag'
