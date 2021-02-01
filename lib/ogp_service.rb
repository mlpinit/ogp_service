require 'securerandom'
require 'json'
require 'nokogiri'
require 'ostruct'
require 'faraday'
require 'time'
require 'redis'

require './lib/ogp_service/html_reader.rb'
require './lib/ogp_service/node.rb'
require './lib/ogp_service/parser.rb'
require './lib/ogp_service/id_generator.rb'

module OGPService
end
