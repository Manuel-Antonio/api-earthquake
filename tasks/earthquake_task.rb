require_relative '../utils/earthquake_fetcher'
require_relative '../config/database.rb'

def fetch_and_insert_earthquakes
  # Conectamos a la BD
  client = connect_to_database
  # Seleccionamos el collection
  collection_earthquakes = client[:earthquakes]
  # Obtener todos los earthquakes válidos
  earthquakes = fetch_earthquakes

  if earthquakes.nil? || earthquakes.empty?
    { message: 'No valid earthquakes data found' }.to_json
  else
    begin
      collection_earthquakes.insert_many(earthquakes, ordered: false)
      { message: 'Earthquakes data inserted successfully' }.to_json
    rescue Mongo::Error::BulkWriteError => e
      errors = e.result['writeErrors']
      duplicate_errors = errors.select { |error| error['code'] == 11000 }
      unless duplicate_errors.empty?
        puts "Ignoring N°#{duplicate_errors.count} duplicate records"
      end
      { error: 'Failed to insert earthquakes data' }.to_json
    rescue StandardError => e
      puts "An error occurred: #{e.message}"
      { error: 'An error occurred while fetching and inserting earthquakes data' }.to_json
    end
  end
end
