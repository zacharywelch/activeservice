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
  def order(*args)
    @params.merge!(sort: preprocess_order_args(args))
    self
  end

  private

  def preprocess_order_args(args)
    args.map! do |arg|
      case arg
      when ::Symbol
        [arg, :desc]
      when ::Hash
        arg.flatten
      end
    end
    order_args = Hash[args].symbolize_keys!
    @owner.field_map.map(order_args, :by => :target).flatten.join('_')
  end

  def preprocess_order_args(args)
    order_args = {}
    if args.is_a? ::Hash
      order_args = args
    else
      order_args[args] = :desc
    end
    order_args.symbolize_keys!
    order_args = @owner.field_map.map(order_args, :by => :target)
  end

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
