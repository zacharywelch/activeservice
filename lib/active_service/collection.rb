class ActiveService::Collection
  include Enumerable

  delegate :to_yaml, :all?, *Array.instance_methods(false), :to => :to_a

  # The array of actual elements returned by index actions
  attr_accessor :elements, :resource_class, :original_params
  
  # ActiveService::Collection is a wrapper to handle parsing index responses that
  # do not directly map to Rails conventions.
  #
  # You can define a custom class that inherets from ActiveService::Collection
  # in order to to set the elements instance. 
  #
  # GET /posts.json delivers following response body:
  #   {
  #     posts: [
  #       {
  #         title: "ActiveService now has associations",
  #         body: "Lorem Ipsum"
  #       }
  #       {...}
  #     ]
  #     next_page: "/posts.json?page=2"
  #   }
  # 
  # A Post class can be setup to handle it with:
  #
  #   class Post < ActiveService::Base
  #     self.site = "http://example.com"
  #     self.collection_parser = PostCollection
  #   end
  #
  # And the collection parser:
  #
  #   class PostCollection < ActiveService::Collection
  #     attr_accessor :next_page
  #     def initialize(parsed = {})
  #       @elements = parsed['posts']
  #       @next_page = parsed['next_page']
  #     end
  #   end
  #
  # The result from a find method that returns multiple entries will now be a 
  # PostParser instance.  ActiveService::Collection includes Enumerable and
  # instances can be iterated over just like an array.
  #    @posts = Post.find(:all) # => PostCollection:xxx
  #    @posts.next_page         # => "/posts.json?page=2"
  #    @posts.map(&:id)         # =>[1, 3, 5 ...]
  #
  # The initialize method will receive the ActiveService::Formats parsed result
  # and should set @elements.
  def initialize(elements = [])
    @elements = elements
  end
  
  def to_a
    elements
  end
  
  def collect!
    return elements unless block_given?
    set = []
    each { |o| set << yield(o) }
    @elements = set
    self
  end
  alias map! collect!

  def first_or_create(attributes = {})
    first || resource_class.create(original_params.update(attributes))
  rescue NoMethodError
    raise "Cannot create resource from resource type: #{resource_class.inspect}"
  end

  def first_or_initialize(attributes = {})
    first || resource_class.new(original_params.update(attributes))
  rescue NoMethodError
    raise "Cannot build resource from resource type: #{resource_class.inspect}"
  end  
end


# class ActiveService::PaginatedCollection < ActiveService::Collection

#   # Our custom array to handle pagination methods
#   attr_accessor :paginatable_array

#   # The initialize method will receive the ActiveService parsed result
#   # and set @elements.
#   def initialize(parsed = {})
#     @elements = parsed["Collection"]
#     setup_paginatable_array(parsed)
#   end

#   # Retrieve response headers and instantiate a paginatable array
#   def setup_paginatable_array(parsed)
#     @paginatable_array ||= begin
#       options = {
#         limit: parsed["Pagination.Limit"].try(:to_i),
#         offset: parsed["Pagination.Offset"].try(:to_i),
#         total_count: parsed["Pagination.TotalCount"].try(:to_i)
#       }

#       Kaminari::PaginatableArray.new(elements, options)
#     end
#   end

#   private

#   # Delegate missing methods to our `paginatable_array` first,
#   # Kaminari might know how to respond to them
#   # E.g. current_page, total_count, etc.
#   def method_missing(method, *args, &block)
#     if paginatable_array.respond_to?(method)
#       paginatable_array.send(method)
#     else
#       super
#     end
#   end
# end