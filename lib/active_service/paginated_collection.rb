require 'kaminari'

class ActiveService::PaginatedCollection < ActiveService::Collection

  # Our custom array to handle pagination methods
  attr_accessor :paginatable_array

  # The initialize method will receive the ActiveResource parsed result
  # and set @elements.
  def initialize(parsed = {})
    @elements = parsed["Collection"]
    setup_paginatable_array(parsed)
  end

  # Retrieve response headers and instantiate a paginatable array
  def setup_paginatable_array(parsed)
    @paginatable_array ||= begin
      options = {
        limit: parsed["Pagination.Limit"].try(:to_i),
        offset: parsed["Pagination.Offset"].try(:to_i),
        total_count: parsed["Pagination.TotalCount"].try(:to_i)
      }

      Kaminari::PaginatableArray.new(elements, options)
    end
  end

  private

  # Delegate missing methods to our `paginatable_array` first,
  # Kaminari might know how to respond to them
  # E.g. current_page, total_count, etc.
  def method_missing(method, *args, &block)
    if paginatable_array.respond_to?(method)
      paginatable_array.send(method)
    else
      super
    end
  end
end