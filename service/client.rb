require 'typhoeus'
require 'json'

class User
  class << self; attr_accessor :base_uri end

  def self.find(id)
    response = Typhoeus::Request.get("#{base_uri}/api/v1/users/#{id}")
    if response.success?
      JSON.parse(response.body)
    elsif response.code == 404
      nil
    else
      raise response.body
    end
  end

  def self.all
    response = Typhoeus::Request.get("#{base_uri}/api/v1/users/#{id}")
    if response.success?
      JSON.parse(response.body)
    elsif response.code == 404
      nil
    else
      raise response.body
    end
  end

  def self.create attributes
    response = Typhoeus::Request.post("#{base_uri}/api/v1/users", :body => attributes.to_json )
    if response.success?
      JSON.parse(response.body)
    elsif response.code == 400
      nil
    else
      raise response.body
    end
  end

  def self.update(id, attributes)
    response = Typhoeus::Request.put("#{base_uri}/api/v1/users/#{id}", :body => attributes.to_json)
    if response.success?
      JSON.parse(response.body)
    elsif response.code == 400 || response.code == 404
      nil
    else
      raise response.body
    end
  end

  def self.destroy(id)
    response = Typhoeus::Request.delete("#{base_uri}/api/v1/users/#{id}")
    response.success?
  end
end