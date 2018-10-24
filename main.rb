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
  redirect to ('/login') unless logged_in?
  erb :index
end

# this is for escaping in sql
def clean_text(input)
  output = input.gsub(/'/) { |x| "\'#{x}" }
  return output
end

def get_show_from_api(name)
  
  
  url = "http://api.tvmaze.com/search/shows?q=#{name}"

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
  
  get_show_from_api(params[:tvshow])

  erb :list
end

get '/get/:name' do
  name = params['name']
  if(load_from_db(name) == false)
    get_show_from_api(name)
    write_show_to_database()
    puts "got show from api"
  end
  # binding.pry
  erb :show
end

def write_show_to_database
  name = clean_text(@name)
  summary = clean_text(@summary)
  
  sql = "INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('#{@showapi_id}', '#{@name}', '#{@premiered}', '#{@image_url}', '#{@summary}');"
  run_sql(sql)
  # redirect to()
end


def load_from_db(name)
name = clean_text(name)
sql = "SELECT * FROM shows WHERE name = '#{name}';"

shows = run_sql(sql)
  if (shows.count == 0)
    return false
  end
  found_show = shows.first
  @id = found_show["id"] # required for rating
  @image_url = found_show["image_url"]
  @summary = found_show["summary"]
  @name = found_show["name"]
  @premiered = found_show["premiered"]

  # binding.pry
  return true
end


get '/login' do
  erb :login
end

post '/session' do
  # does user exist
  user = User.find_by(username: params[:username])
  if user && user.authenticate(params[:password])
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

get '/rate/:id' do

  sql = "SELECT * FROM shows WHERE id = '#{params[:id]}';"
  shows = run_sql(sql)
    found_show = shows.first
    @id = found_show["id"] # required for rating
    @image_url = found_show["image_url"]
    @summary = found_show["summary"]
    @name = found_show["name"]
    @premiered = found_show["premiered"]
    
    # binding.pry

  erb :rate
end

post '/rate/:id' do  
  add_rating(session[:user_id], params[:id], params[:rate]) 
end


# def get_users(user_id)
#   sql = "SELECT * FROM users;"

# end

# def get_shows_by_users(user_id)
#   sql = "SELECT * FROM users;"
# end

def add_rating(current_user, show_id, rating)
  # binding.pry

  sql = "INSERT INTO watches (user_id, show_id, rating) VALUES ('#{current_user}', '#{show_id}', '#{rating}');"
  run_sql(sql)
  redirect to('/')
end



