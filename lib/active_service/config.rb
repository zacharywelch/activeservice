#require_relative 'simple_parser'
require_relative 'cbparser'

module ActiveService  
  class Config
    class << self
      attr_writer :parser

      def parser
        @parser ||= ::CbParser.new
      end
    end
  end
end
