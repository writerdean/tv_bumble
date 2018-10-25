require 'sinatra'
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
  redirect to ('/login') unless logged_in?
  # binding.pry
  puts "Current user is #{current_user.username}"
  puts "Current user id is #{current_user.id}"
  get_users()
  get_shows_by_user(current_user)
  erb :index
end

# this is for escaping in sql
def clean_text(input)
  output = input.gsub(/'/) { |x| "\'#{x}" }
  return output
end

def get_show_from_api(name)
  
  puts "From method get_show_from_api:  searching for show " + name
  
  url = "http://api.tvmaze.com/search/shows?q=#{name}"
  puts "url is " + url

  @search_results = HTTParty.get(url)

  @search_parsed = @search_results.parsed_response
  first_result = @search_results.first
  @tvshow = first_result["show"]
  @showapi_id = @tvshow["id"]
  @url = @tvshow["url"]
  @name = clean_text(@tvshow["name"])
  @image_url = @tvshow["image"]["medium"]
  @summary = clean_text(@tvshow["summary"])
  @premiered = @tvshow["premiered"]
  # binding.pry

end

get '/search' do
  
  puts "From route /search:  getting search result while searching for tv show #{params[:tvshow]}"

  get_show_from_api(params[:tvshow])

  puts "searched for show"
  puts 'tv show found, list created'
  erb :list
end

get '/get/:name' do
  puts "From route /get/:name = checking if in database"
  name = params['name']
  if(load_from_db(name) == false)
    get_show_from_api(name)
    # add if statement - if name already in db, do not add
    write_show_to_database()
    puts "got show from api"
  end
  erb :show
end

def write_show_to_database
  name = clean_text(@name)
  summary = clean_text(@summary)
  
  sql = "INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('#{@showapi_id}', '#{@name}', '#{@premiered}', '#{@image_url}', '#{@summary}');"
  run_sql(sql)
  puts "Put show into shows database"
  # redirect to()
end


def load_from_db(name)
  puts "looking for tv show in the database"
name = clean_text(name)
sql = "SELECT * FROM shows WHERE name = '#{name}';"

shows = run_sql(sql)
  if (shows.count == 0)
    return false
  end
binding.pry
found_show = shows.first
@image_url = found_show["image_url"]
@summary = found_show["summary"]
@name = found_show["name"]
@premiered = found_show["premiered"]
  return true
end


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
  puts 'goodbye'
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
end

def add_rating(current_user, show_id, rating)
  # binding.pry
  sql = "INSERT INTO watches (user_id, show_id, rating) VALUES ('#{current_user}', '#{show_id}', '#{rating}');"
  run_sql(sql)
  redirect to('/')
end

get '/users/:username' do
  erb :users
end

def get_users()
  sql = "SELECT * FROM users;"
  @users = run_sql(sql)
  # binding.pry
end

def get_shows_by_user(current_user)
  sql = "SELECT * FROM watches WHERE user_id = #{current_user.id};"
  @user_shows_results = run_sql(sql)
  # binding.pry
end

