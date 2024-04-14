require 'sinatra'
require 'httparty'
require 'json'
require 'mongo'
require 'rack/cors'

require_relative './tasks/earthquake_task.rb'
require_relative './controllers/earthquakes_controller.rb'
require_relative './timezone.rb'

def init_register_earthquakes
  result = fetch_and_insert_earthquakes()
end

def init_app 
  Thread.new { fetch_earthquakes }
end 

class MyApp < Sinatra::Base

  use Rack::Cors do
    allow do
      origins 'http://localhost:4200'
      resource '*', headers: :any, methods: [:get, :post, :options]
    end
  end

  use EarthquakesController

  configure do 
    init_register_earthquakes()
  end

end

MyApp.run!
