require 'active_service/collection'

module ActiveService  
  class Config
    class << self
      attr_accessor :hydra      
      attr_writer   :default_collection_parser
      
      def default_collection_parser
        @default_collection_parser ||= ActiveService::Collection
      end
    end
  end
end
