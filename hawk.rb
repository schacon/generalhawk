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
  property :id,          Serial
  property :agent,       String, :key => true 
  property :url,         String
  property :description, String
  property :last_build,  Time
  property :heartbeat,   Time
  property :hidden,      Boolean

  def build
    builds.last
  end

end

class Build
  include DataMapper::Resource 
  belongs_to :agent
  property :id,          Serial
  property :branch,      String, :key => true
  property :status,      String
  property :sha,         String
  property :message,     String
  property :author,      String
  property :out,         Text
  property :built,       Time
end

class Token
  include DataMapper::Resource 
  property :id,         Serial
  property :token,      String, :key => true
end

DataMapper.auto_upgrade!

## -- WEBSITE STUFF --

get '/' do
  @agents = Agent.all(:order => [:last_build.desc])
  erb :index
end

# get agent data
get '/agent/:agent' do
  @agent = Agent.first({:agent => params[:agent]})
  erb :agent
end

#{
# "agent"=>"test1",
# "description"=>nil,
# "url"=>"https://github.com/libgit2/libgit2",
#
# "branch"=>"master",
# "output"=>"blblblblblb albal",
# "status"=>"good",
# "sha"=>"015334209c83065f42a677acb25fefe2cb09b394",
# "message"=>"this is a commit"
# }
post '/update/:token' do
  token = Token.first(:token => params[:token])
  if !token
    status 401 # unauthorized
    return "nope"
  end

  push = JSON.parse(params[:data])

  is_build = false
  if push['status']
    is_build = true
  end

  # select or add agent
  agent = Agent.first(:agent => push['agent'])
  agent = Agent.new if !agent
  agent.attributes = {
    :agent => push['agent'],
    :description => push['description'],
    :url => push['url'],
  }
  agent.last_build => Time.now if is_build
  agent.heartbeat => Time.now
  agent.save

  if is_build
    # create new build
    build = Build.new
    build.agent = agent
    build.branch  = push['branch']
    build.status  = push['status']
    build.sha     = push['sha']
    build.message = push['message'].split("\n").first[0, 40]
    build.author  = push['author']
    build.built   = Time.now
    build.out     = push['output']
    build.save
  end
end

def time_ago(to_time)
  from_time = Time.now
  min = (((to_time.to_i - from_time.to_i).abs)/60).round

  case min
    when 0..1            then "just a bit ago"
    when 2..44           then "#{min} minutes ago"
    when 45..89          then "about an hour ago"
    when 90..1439        then "about #{(min.to_f / 60.0).round} hours ago"
    when 1440..2529      then "about a day ago"
    when 2530..43199     then "#{(min.to_f / 1440.0).round} days ago"
    when 43200..86399    then "about a month ago"
    else "forever ago"
  end
end

