require 'active_service/collection'

class CbCollection < ActiveService::Collection

  # The initialize method will receive the ActiveResource parsed result
  # and set @elements.
  def initialize(parsed = {})
    @elements = parsed["Collection"]
  end
end