$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'active_attr'
require 'client/model'
require 'client/user'
require 'client/security_tag'

I18n.enforce_available_locales = true