# = Relation
# 
# Relation sets up the association proxy methods.
class Relation

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
    args = args.flatten.join('_') if args.is_a? Hash
    @params.merge!(sort: args)
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
