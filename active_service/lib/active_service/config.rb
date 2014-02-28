require_relative 'simple_parser'

module ActiveService
  class Config
    class << self
      attr_writer :parser

      def parser
        @parser ||= ::SimpleParser.new
      end
    end
  end
end
