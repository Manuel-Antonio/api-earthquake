require 'mongo'

def connect_to_database
    Mongo::Logger.logger.level = ::Logger::FATAL
    database = "earthquakes"
    uri = "mongodb://127.0.0.1:27017"
    client = Mongo::Client.new("#{uri}/#{database}")

    client
end
