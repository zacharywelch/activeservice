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
    args = Hash[args, :asc] if args.is_a? ::Symbol
    args = @owner.field_map.map(args.symbolize_keys!, :by => :target)
    @params.merge!(sort: args.flatten.join('_'))
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
