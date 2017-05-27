# module ActiveService::Model::Attributes
#   module AttributeValues  
#     extend ActiveSupport::Concern

#     included do
#       class_eval do
#         class << self 
#           alias_method_chain :attribute!, :values 
#         end
#       end
#     end

#     module ClassMethods
#       def attribute_with_values!(name, options = {})
#         attribute_without_values!(name, options)
#         puts "hola"
#       end
#     end
#   end
# end

# # # module ActiveService::Model::Attributes
# # #   module AttributeValues  
# # #     extend ActiveSupport::Concern

# # #     def self.included(base)
# # #     #   base.instance_eval do 
# # #     #     # puts "class = #{self.class}, public methods = #{public_methods(false).sort}"
# # #       # instance_eval do
# # #       puts base.to_s
# # #       puts "class=#{self.class}, base=#{base}, #{base.public_methods(false).sort.grep /attribute/}"
# # #       # end
# # #       if base.to_s == "ActiveService::Base" 
# # #         base.instance_eval do
# # #           class << self
# # #             alias_method_chain :attribute!, :values 
# # #           end
# # #         end
# # #       end
# # #     end

# # #     module ClassMethods
# # #       def attribute_with_values!(name, options = {})
# # #         attribute_without_values!(name, options)
# # #         puts "hola"
# # #       end

# # #       # def attribute!(name, options = {})
# # #       #   super(name, options)
# # #       #   puts "hola"
# # #       # end
# # #     end
# # #   end
# # # end
