require 'json'

# Parser for CareerBuilder API
class CbParser
  def parse_single(response)
    JSON.parse(response)
  end

  def parse_collection(response)
    JSON.parse(response)["Collection"]
  end
end
