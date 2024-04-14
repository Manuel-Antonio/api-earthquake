require 'httparty'

def fetch_earthquakes
  response = HTTParty.get('https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson')
  return nil unless response.success?

  data = JSON.parse(response.body)
  data['features'].map do |feature|
    next unless valid_earthquake?(feature)

    {
      _id: feature['id'],
      mag: feature['properties']['mag'],
      place: feature['properties']['place'],
      time: feature['properties']['time'],
      url: feature['properties']['url'],
      tsunami: feature['properties']['tsunami'],
      mag_type: feature['properties']['magType'],
      title: feature['properties']['title'],
      coordinates: {
        longitude: feature['geometry']['coordinates'][0],
        latitude: feature['geometry']['coordinates'][1]
      }
    }
  end.compact
end

def valid_earthquake?(earthquake)
  return false if earthquake['properties']['title'].nil? || earthquake['properties']['url'].nil? || earthquake['properties']['place'].nil? || earthquake['properties']['magType'].nil?

  mag = earthquake['properties']['mag'].to_f
  latitude = earthquake['geometry']['coordinates'][1].to_f
  longitude = earthquake['geometry']['coordinates'][0].to_f

  return false if mag < -1.0 || mag > 10.0
  return false if latitude < -90.0 || latitude > 90.0
  return false if longitude < -180.0 || longitude > 180.0

  true
end
