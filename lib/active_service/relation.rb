# = Relation
# 
# Relation sets up the association proxy methods.
class Relation < ActiveSupport::ProxyObject

  def initialize(owner)
    @owner = owner
    @target = nil
    @params = {}
  end

  def where(params)
    @params.merge!(params)
    self
  end

  # args = :name => { :sort => :name }
  # args = { name: :desc } => { :sort => "name_desc" }
  def order(args)
    return self if args.nil?
    order_args = {}
    if args.is_a? ::Hash
      order_args = args
    else
      order_args[args] = :desc
    end
    order_args.symbolize_keys!
    # preprocess_order_args(args)
    # clauses = field_map.map(clauses, :by => :target)
    order_args = @owner.field_map.map(order_args, :by => :target)
    @params.merge!(sort: order_args.flatten.join('_'))
    self
  end

  private

  def loaded_target
    @target ||= load_target!
  end

  def load_target!
    @owner.find(:all, params: @params)
  end

  def method_missing(m, *args, &block)
    loaded_target.send(m, *args, &block)
  end
end
