$:.unshift File.dirname(__FILE__)

require 'active_attr'
require 'faraday'
require 'active_support/core_ext/hash'

require 'active_service/version'
require 'active_service/api'
require 'active_service/base'
require 'active_service/errors'
require 'active_service/collection'

module ActiveService
end