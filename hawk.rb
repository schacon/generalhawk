require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require 'json'
require 'pp'

## -- DATABASE STUFF --

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/local.db")

class Agent
  include DataMapper::Resource 
  has n, :builds
  property :id,         Serial
  property :agent,      String, :key => true 
  property :last_build, DateTime
end

class Build
  include DataMapper::Resource 
  belongs_to :agent
  property :id,          Serial
  property :description, String
  property :url,         String
  property :branch,      String, :key => true
  property :status,      String
  property :last_status, String
  property :sha,         String
  property :short_message, String
  property :full_message,  String
  property :built,       DateTime
end

DataMapper.auto_upgrade!

## -- WEBSITE STUFF --

get '/' do
  @agents = Agent.all(:order => [:last_build.desc])
  erb :index
end

# get agent data
get '/agent/:agent' do
  erb :agent
end

# TODO: get build 

post '/update/:token' do
  push = JSON.parse(params[:data]) 
  pp push
end
