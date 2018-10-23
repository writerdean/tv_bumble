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

# this is for escaping in sql
def clean_text(input)
  output = input.gsub(/'/) { |x| "\'#{x}" }
  return output
end

def get_show_from_api(name)
  
  puts "searching for show " + name
  
  url = "http://api.tvmaze.com/search/shows?q=#{name}"
  puts "url is " + url

  search_results = HTTParty.get(url)
  # @search_parsed = search_results.parsed_response
  # binding.pry
  first_result = search_results.first
  @tvshow = first_result["show"]
  @showapi_id = @tvshow["id"]
  @url = @tvshow["url"]
  @name = clean_text(@tvshow["name"])
  @image_url = @tvshow["image"]["medium"]
  @summary = clean_text(@tvshow["summary"])
  @premiered = @tvshow["premiered"]
  # puts @search_parsed
  # puts @tvshow
  puts @showapi_id
  puts @url
  puts @name
  puts @image_url
  puts @summary
  puts @premiered
end

get '/search' do
  
  puts "Getting search result while searching for tv show #{params[:tvshow]}"

  get_show_from_api(params[:tvshow])

  puts "searched for show"
  puts 'tv show found, list created'
  erb :list
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
    session[:user_id] = user.id  #in brackets use a unique identifier
    redirect to('/')
  else 
    # binding.pry
    erb :login
  end
end

delete '/session' do
  # destroy the session
  session[:user_id] = nil
    redirect to('/login')
end

get '/rate' do

  #  button id = zero
  #  button id = one
  #  button id = two
  #  button id = three
  #  button id = four
  #  button id = five

  # at button click, ad user_id, show_id and rating to watches table
  
  erb :rate
end

get '/watch/:name' do
  puts "Yes, I watched the show #{params[:name]}"
  # get user_id
  # get show_name
  # you have to insert it into the shows table before it has a show_id!!!!!!!!!!!!!!!!!

  get_show_from_api(params[:name])
  puts "user indicated that they watched the show, so searching for show again"
  # binding.pry
  sql = "INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('#{@showapi_id}', '#{@name}', '#{@premiered}', '#{@image_url}', '#{@summary}');"
  puts sql
  puts "we tried to put it into the database"
  # # sql = "INSERT INTO watches (user_id, show_id) VALUES (#{current_user.id}, #{})"
  run_sql(sql)
  redirect to('/')
end
