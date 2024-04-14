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
    p "--------------------------------"
    p result
    p "--------------------------------"
  # loop do
    

  #   # Esperar 24 horas antes de la próxima ejecución
  #   sleep(24 * 60 * 60)
  # end
end

def init_app 
  Thread.new { fetch_earthquakes }
end 

# Se ejecuta tambien porque hereda de Sinatra::Base
class MyApp < Sinatra::Base
  # Configuración para habilitar CORS
  use Rack::Cors do
    allow do
      origins 'http://localhost:4200'
      resource '*', headers: :any, methods: [:get, :post, :options]
    end
  end

  use EarthquakesController

  # Archivos de inicializacion
  configure do 
    init_register_earthquakes()
  end

end

# Iniciar la aplicación principal
MyApp.run!
