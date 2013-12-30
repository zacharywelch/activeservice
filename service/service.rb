require 'active_record'
require 'sinatra'
require 'logger'
require './models/user'

# setting up the environment
env_index = ARGV.index("-e")
env_arg = ARGV[env_index + 1] if env_index
env = env_arg || ENV["SINATRA_ENV"] || "development"
databases = YAML.load_file("config/database.yml")
ActiveRecord::Base.establish_connection(databases[env])

# place connection back in pool after request is over 
after do
  ActiveRecord::Base.clear_active_connections!
end

# HTTP entry points

# get all users
get '/api/v1/users' do
  users = User.where(params)
  if users    
    users.to_json(:except => [:created_at, :updated_at])
  else
    error 404, {:error => "users not found"}.to_json
  end
end

# get a user by id
get '/api/v1/users/:id' do
  user = User.find_by_id(params[:id])
  if user
    user.to_json
  else
    error 404, {:error => "user not found"}.to_json
  end
end

# create a new user
post '/api/v1/users' do
  begin
    user = User.create(JSON.parse(request.body.read))
    if user.valid?
      user.to_json
    else
      error 400, user.errors.to_json
    end
  rescue => e
    error 400, e.message.to_json
  end
end

# update an existing user
put '/api/v1/users/:id' do 
  user = User.find_by_id(params[:id])
  if user 
    begin
      if user.update_attributes(JSON.parse(request.body.read))
        user.to_json
      else
        error 400, user.errors.to_json
      end
    rescue => e
      error 400, e.message.to_json
    end
  else
    error 404, {:error => "user not found"}.to_json
  end
end

# destroy an existing user
delete '/api/v1/users/:id' do
  user = User.find_by_id(params[:id])
  if user
    user.destroy
    user.to_json
  else
    error 404, {:error => "user not found"}.to_json
  end
end