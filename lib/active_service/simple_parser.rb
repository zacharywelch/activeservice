class SimpleParser
  def parse_single(response)
    response
  end

  def parse_collection(response)
    JSON.parse(response)
  end
end