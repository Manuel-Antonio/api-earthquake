require 'sinatra/base'
require_relative '../config/database.rb'


class EarthquakesController < Sinatra::Base
    configure do
        set :client, connect_to_database
        set :collection, settings.client[:earthquakes]
    end

    before do
        @client = settings.client
        @collection = settings.collection
    end

    get '/features' do
      begin
        content_type :json
        
        # Obtener todos los terremotos de la colección
        earthquakes = @collection.find.to_a
      
        # Filtrar por mag_type si está presente en los parámetros
        mag_types = params[:filters] && params[:filters][:mag_type]&.map(&:downcase)
        
        if mag_types
          earthquakes = earthquakes.select { |earthquake| mag_types.include?(earthquake['mag_type'].downcase) }
        end

        # Verificar si no se encontraron terremotos después del filtrado
        if earthquakes.empty?
          status 404
          return { message: 'No earthquakes found for the specified filters' }.to_json
        end

        # Número de elementos por página
        per_page = params[:per_page]&.to_i || 20
        per_page = [per_page, 1000].min # Limitar a 1000 elementos por página
      
        # Obtener el número de página solicitado
        page_number = params[:page]&.to_i || 1
      
        # Calcular el índice de inicio y fin para los elementos de la página solicitada
        start_index = (page_number - 1) * per_page
        end_index = start_index + per_page - 1
      
        # Obtener los elementos correspondientes a la página solicitada
        paged_earthquakes = earthquakes[start_index..end_index]

        # Transformar los terremotos en el formato especificado
        features = paged_earthquakes.map do |earthquake|
          {
            id: earthquake['_id'],
            type: 'feature',
            attributes: {
              external_id: earthquake['_id'],
              magnitude: earthquake['mag'],
              place: earthquake['place'],
              time: Time.at(earthquake['time'] / 1000).to_s,
              tsunami: earthquake['tsunami'] == 1 ? true : false,
              mag_type: earthquake['mag_type'],
              title: earthquake['title'],
              coordinates: {
                longitude: earthquake['coordinates']['longitude'],
                latitude: earthquake['coordinates']['latitude']
              },
              comments: earthquake['comments']
            },
            links: {
              external_url: earthquake['url']
            }
          }
        end
      
        # Calcular el número total de páginas
        total_pages = (earthquakes.count / per_page.to_f).ceil
      
        # Construir el JSON con los features y la información de paginación
        json_response = {
          data: features,
          pagination: {
            current_page: page_number,
            total: earthquakes.count,
            per_page: per_page,
            total_pages: total_pages
          }
        }
      
        json_response.to_json
      rescue => e
        status 500
        { message: 'An internal error occurred on the server' }.to_json
      end
      end
      

    get '/features/:id' do
        content_type :json
        id = params[:id]
        earthquake = @collection.find(_id: id).first

        if earthquake
          {
            id: earthquake['_id'],
            type: 'feature',
            attributes: {
              external_id: earthquake['_id'],
              magnitude: earthquake['mag'],
              place: earthquake['place'],
              time: Time.at(earthquake['time'] / 1000).to_s,
              tsunami: earthquake['tsunami'] == 1 ? true : false,
              mag_type: earthquake['mag_type'],
              title: earthquake['title'],
              coordinates: {
                longitude: earthquake['coordinates']['longitude'],
                latitude: earthquake['coordinates']['latitude']
              },
              comments: earthquake['comments']
            },
            links: {
              external_url: earthquake['url']
            }
          }.to_json
        else
        status 404
        { error: "Earthquake with ID #{id} not found" }.to_json
        end
    end

    post '/features/comment' do
      content_type :json
    
      # Obtener los datos del payload
      request.body.rewind
      payload = JSON.parse(request.body.read)
    
      # Obtener el feature_id y el body del payload
      feature_id = payload['feature_id']
      body = payload['body']

      # Validar que el body del comentario no esté vacío
      if body.nil? || body.strip.empty?
        status 400
        return { error: 'Comment body cannot be empty' }.to_json
      end
    
      # Validar que el payload contiene el feature_id y el body
      unless payload.key?('feature_id') && payload.key?('body')
        status 400
        return { error: 'Missing feature_id or body in payload' }.to_json
      end

      # Validar que el feature_id es string
      unless feature_id.is_a?(String)
        status 400
        return { error: 'Invalid feature_id. It must be a positive integer' }.to_json
      end
    
      # Obtener el feature asociado al feature_id
      feature = @collection.find(_id: feature_id).first
    
      # Verificar si el feature existe
      unless feature
        status 404
        return { error: "Feature with ID #{feature_id} not found" }.to_json
      end
    
      # Crear el comentario y agregarlo al feature
      comment = { body: body, created_at: Time.now }
      feature['comments'] ||= [] # Inicializar la lista de comentarios si es nil
      feature['comments'] << comment
    
      # Actualizar el feature en la base de datos
      @collection.update_one({ _id: feature_id }, feature)
    
      # Devolver el comentario creado como respuesta
      status 201
      comment.to_json
    end
    
end
