require "json"
require "uri"
require "net/http"
require 'pp'

class Hawk

  def self.post(status)
    puts "POST"
    message = ENV['MESSAGE']
    author = ENV['AUTHOR']
    sha = ENV['SHA']
    out = ENV['OUTPUT']
    config = Hawk.config
    data = {
        "agent"       => config[:agent],
        "description" => config[:description],
        "branch"      => "master",
        "sha"         => sha,
        "status"      => status,
        "url"         => config[:url],
        "message"     => message,
        "output"      => out
      }
    pp data
    self.post_update(data.to_json) # POST JSON TO URL
    puts
  end

  def self.config
    return @config if @config
    c = {}
    config = `git config --list`
    config.split("\n").each do |line| 
      k, v = line.split('=')
      c[k] = v
    end
    url = ''
    u = c['remote.origin.url']
    if m = /github\.com.(.*?)\/(.*?)\.git/.match(u)
      user = m[1]
      proj = m[2]
      url = "https://github.com/#{user}/#{proj}"
    end

    head_file = File.join(File.dirname(__FILE__), %w[.. HEAD])
    b = File.read(head_file)
    branch = b.chomp.split('/').last rescue ''

    @config = {
      :server    => c['hawk.server'],
      :token     => c['hawk.token'],
      :agent     => c['hawk.agent'],
      :description => c['hawk.description'],
      :branch => branch,
      :url => url
    }
  end

  def self.post_update(data)
    config = Hawk.config
    ws = "#{config[:server]}/update/#{config[:token]}"
    x = Net::HTTP.post_form(URI.parse(ws), {'data' => data})
    puts x.body
  end

end

