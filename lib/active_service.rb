$LOAD_PATH.unshift(File.dirname(__FILE__))

# ActiveService combines the ActiveModel features of ActiveAttr with a 
# persistence mechanism using Typhoeus.
require 'active_attr'
require 'typhoeus'

module ActiveService
  autoload :Base,       'active_service/base'
  autoload :Collection, 'active_service/collection'
  autoload :Config,     'active_service/config'
  autoload :UriBuilder, 'active_service/uri_builder'
end

# There are some ActiveAttr patches contained here.
require 'ext/active_attr'
