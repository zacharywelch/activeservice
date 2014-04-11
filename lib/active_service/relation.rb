# = Relation
# 
# Relation sets up the association proxy methods.
class Relation < ActiveSupport::BasicObject

  def initialize(owner)
    @owner = owner
    @target = nil
    @params = {}
  end

  def where(params)
    @params.merge!(params)
    self
  end

  def order(args)
    # preprocess_order_args(args)
    # clauses = field_map.map(clauses, :by => :target)
    args = args.flatten.join('_') if args.is_a? Hash
    @params.merge!(sort: args)
    self
  end

  private

  def preprocess_order_args(args)
    case args
    when Symbol
      
    when Hash

    end
       
  end

  def loaded_target
    @target ||= load_target!
  end

  def load_target!
    @owner.find(:all, params: @params)
  end

  def method_missing(m, *args, &block)
    if ::Array.method_defined?(m)
      loaded_target.send(m, *args, &block)
    else
      loaded_target.send(m, *args, &block)
    end
  end
end
