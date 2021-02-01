require 'sinatra'
require "sinatra/json"
require './lib/ogp_service'

get '/stories/:id' do
  begin
    node = OGPService::Node.new(id: params[:id].to_s)
    if node.initiated?
      if node.pending_or_done?
        json node.data
      else
        node.set_pending_state
        node.scrape if node.initiator?
        json node.data
      end
    else
      error 400, "id: #{params[:id]} not recognized."
    end
  rescue => e
    puts e # log error
    halt 500, "The request could no be processed."
  end
end

post '/stories' do
  if params['url']
    begin
      json OGPService::IDGenerator.new(url: params['url']).run
    rescue => e
      puts e # log error
      halt 500, "The request could no be processed."
    end
  else
    error 400, "URL param must be provided."
  end
end
