require 'sinatra'
require 'sinatra/reloader' #only reloads main.rb
require 'pg'
require 'pry'
require 'httparty'

require_relative 'db_config'
require_relative 'models/show'
require_relative 'models/watches'
require_relative 'models/user'


binding.pry