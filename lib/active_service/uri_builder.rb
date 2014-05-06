module ActiveService
  module UriBuilder
    extend self

    def find_all(resource, options = {})
      "#{find_every(resource)}#{format(options[:format])}"
    end

    def find_one(resource, id, options = {})
      "#{find_single(resource, resource_id)}#{format(options[:format])}"
    end

    def belongs_to(resource, id, options = {})
      "#{find_single(resource, resource_id)}#{format(options[:format])}"
    end

    def has_one(resource, resource_id, nested_resource, options = {})
      "#{find_single(resource, resource_id)}/#{nested_resource.element_name}#{format(options[:format])}"
    end

    def has_many(resource, resource_id, nested_resource, options = {})
      "#{find_single(resource, resource_id)}/#{nested_resource.collection_name}#{format(options[:format])}"
    end

    private 

    def find_every(resource)
      "#{resource.base_uri}/#{resource.collection_name}"
    end

    def find_single(resource, id)
      "#{resource.base_uri}/#{resource.collection_name}/#{id}"
    end

    def format(extension)
      ".#{extension}" unless extension.nil? 
    end
  end
end