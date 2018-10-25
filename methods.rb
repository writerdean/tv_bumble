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
    binding.pry
    erb :login
  end
end

get '/search' do

  url = "http://api.tvmaze.com/search/shows?q=#{params[:tvshow]}"

  @search_results = HTTParty.get(url)
  binding.pry
  # @search_parsed = @search_results.parsed_response["Search"]
  # @search_parsed.each do |show|
  #   puts show["name"]
  # end

  @search_results.each do |result|
    result.each do |show|
      puts show
    end
  end


  erb :list
end

get '/found/:name' do

  @tvshow = HTTParty.get("http://api.tvmaze.com/search/shows?q=#{params[:name]}")
  @image_url = @tvshow["image"]["medium"]
  @summary = clean_text(@tvshow["summary"])
  
  erb :show
end

get '/get/:name' do
  name = params['name']
  if(load_from_db(name) == false)
    get_movie_from_api(name)
    write_movie_to_database()
  end
  erb :show
end

def load_from_db(name)
name = clean_text(name)
sql = "SELECT * FROM found_films WHERE title = '#{name}';"

shows = run_sql(sql)
if (shows.count == 0)
  return false
end
found_show = shows.first
@showapi_id = found_show["id"]
@image_url = found_show["image"]["medium"]
@summary = found_show["summary"]
@name = found_show["name"]
@premiered = found_show["premiered"]
return true
end


def get_show_from_api(name)
  
  puts "searching for show " + name
  
  url = "http://api.tvmaze.com/search/shows?q=#{name}"
  puts "url is " + url

  search_results = HTTParty.get(url)
  # @search_parsed = search_results.parsed_response
  first_result = search_results.first
  @tvshow = first_result["show"]
  @showapi_id = @tvshow["id"]
  @url = @tvshow["url"]
  @name = clean_text(@tvshow["name"])
  @image_url = @tvshow["image"]["medium"]
  @summary = clean_text(@tvshow["summary"])
  @premiered = @tvshow["premiered"]
  binding.pry
end

get '/watch/:name' do
  puts "Yes, I watched the show #{params[:name]}"
  get_show_from_api(params[:name])
  puts "user indicated that they watched the show, so searching for show again"
  # binding.pry
  sql = "INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('#{@showapi_id}', '#{@name}', '#{@premiered}', '#{@image_url}', '#{@summary}');"
  run_sql(sql)
  redirect to('/')
end

# this is for escaping in sql
def clean_text(input)
  output = input.gsub(/'/) { |x| "\'#{x}" }
  return output
end

# this is escaping for Ruby in HTML
# def clean_text(input)
#   output = input.gsub(/'/) { |x| "\\#{x}" }
#   puts "cleaned: " + output
#   return output
# end