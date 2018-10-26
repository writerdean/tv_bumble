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
  get_users()
  get_shows_by_user(current_user.id)
  # binding.pry
  erb :index
end

# this is for escaping in sql
def clean_text(input)
  output = input.gsub(/'/) { |x| "\'#{x}" }
  return output
end

def get_show_from_api(name)
  # puts "getting show from api"
  url = "http://api.tvmaze.com/search/shows?q=#{name}"
  # puts "url is " + url

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

  # binding.pry
  erb :list
end

get '/get/:name' do
  name = params['name']
  if(load_from_db(name) == false)
    get_show_from_api(name)
    # - if name already in db, do not add
    write_show_to_database()
    # puts "got show from api"
  end
  erb :show
end


def write_show_to_database
  name = clean_text(@name)
  summary = clean_text(@summary)
  
  # sql = "INSERT INTO shows (show_id, name, premiered, image_url, summary) VALUES ('#{@showapi_id}', '#{@name}', '#{@premiered}', '#{@image_url}', '#{@summary}');"
  # run_sql(sql)

  s = Show.new
  s.show_id = @showapi_id
  s.name = @name
  s.premiered = @premiered
  s.image_url = @image_url
  s.summary = @summary
  s.save

  # redirect to()
end


def load_from_db(name)
  name = clean_text(name)
  # sql = "SELECT * FROM shows WHERE name = '#{name}';"

  show = Show.find_by(name: name)
  return false if show.nil?
  # binding.pry
  @id = show.id # required for rating
  @showapi_id = show.show_id
  @image_url = show.image_url
  @summary = show.summary
  @name = show.name
  @premiered = show.premiered
  return true
end


get '/login' do
  erb :login
end

post '/session' do
  # does user exist
  user = User.find_by(username: params[:username])
  if user && user.authenticate(params[:password])
    # puts "User and password correct"
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

get '/rate/:id' do

  # sql = "SELECT * FROM shows WHERE id = '#{params[:id]}';"
  show = Show.find_by(id: params[:id])
  # shows = run_sql(sql)
    # found_show = shows.first
    @id = show.id # required for rating
    @image_url = show.image_url
    @summary = show.summary
    @name = show.name
    @premiered = show.premiered
    
    # binding.pry

  erb :rate
end

get '/watch/:name' do
end

post '/rate/:id' do  
  add_rating(session[:user_id], params[:id], params[:rate]) 
end

def add_rating(current_user, show_id, rating)
  # binding.pry
  # sql = "INSERT INTO watches (user_id, show_id, rating) VALUES ('#{current_user}', '#{show_id}', '#{rating}');"
  # run_sql(sql)
    i = Watch.new
    i.user_id = "#{current_user}"
    i.show_id = "#{show_id}"
    i.rating = "#{rating}"
    i.save
  # binding.pry
  redirect to('/')
end

get '/users/:id' do
  get_users()
  get_shows_by_user(params[:id])
  erb :users
end

def get_users()
  # sql = "SELECT * FROM users;"
  @users = User.all
  # @users = run_sql(sql)
  # binding.pry
end

def get_shows_by_user(id)
  puts "username = #{id}"
  # sql = "SELECT * FROM watches WHERE user_id = '#{id}' ORDER BY rating DESC;"
  @user_shows_results = Watch.where(user_id: id).order(rating: :desc)

  # run_sql(sql)
  # binding.pry
end

