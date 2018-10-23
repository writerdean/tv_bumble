require 'sinatra'
require 'sinatra/reloader' #only reloads main.rb
require 'pg'
require 'pry'
require 'httparty'

require_relative 'db_config'
require_relative 'models/show'
require_relative 'models/watches'
require_relative 'models/user'


enable :sessions

helpers do
  def logged_in?
    !!current_user
  end

  def current_user
    User.find_by(id: session[:user_id])
  end
end

def run_sql(sql)
  conn = PG.connect(dbname: 'tv_bumble')
  result = conn.exec(sql)
  conn.close
  result
end


get '/' do
  erb :index
end

get '/search' do

  search_results = HTTParty.get("http://api.tvmaze.com/search/shows?q=#{params[:tvshow]}")
  search_parsed = search_results.parsed_response
  # search_results.each do |tvshow|
  @tvshow = search_results[0]["show"]
  @url = @tvshow["url"]
  @name = @tvshow["name"]
  @image_url = @tvshow["image"]["medium"]
  @summary = @tvshow["summary"]
  @premiered = @tvshow["premiered"]

  puts 'tv show found, list created'
  erb :list
  # binding.pry
end
# end

get '/login' do
  erb :login
end


post '/session' do
  # does user exist
  user = User.find_by(username: params[:username])
  if user && user.authenticate(params[:password])
    puts "User and password correct"
  # if both true, you are good
  # create a session
    session[:user_id] = user.id  #in brackets use a unique identifier
    redirect to('/')
  else 
    # try again
    binding.pry
    erb :login
  end
end

delete '/session' do
  # destroy the session
  session[:user_id] = nil
    redirect to('/login')
end



