require 'json'
require 'yaml'
require 'net/http'
require 'open-uri'

raise 'OUTPUT is missing' if ENV['OUTPUT'] == nil || ENV['OUTPUT'] == ''

begin
json = JSON.parse(File.read(ENV['INPUT']))
rescue Errno::ENOENT
  raise "cant read file '#{ENV['INPUT']}'"
end
raise "'item' key not found. Probably collection version 1 is used. Please try again with colelctio version 2" unless json['item']

counter = 0

data = json['item'].map do |item|
  puts "Converting '#{item['name']}'"
  counter += 1
  headers = Hash[item['request']['header'].map{|h| [h['key'], h['value']] }]
  response_headers = {'Access-Control-Allow-Origin' =>  '*'}
  body = open(item['request']['url'], headers).read rescue nil
  {
    "name" => item['name'],
    "request" =>  {
      "uri" => URI.parse(item['request']['url']).path,
      "method" => item['request']['method'],
      "headers" => ENV['NO_REQUEST_HEADERS'] ? {} : headers,
      "body" => "*"
    },
    "response" => {
      "code" => 200,
      "body" => body,
      "headers" => response_headers
    }
  }
end
File.open(ENV['OUTPUT'], 'w'){|f| f.write(data.to_yaml) }

puts "Converted #{counter} endpoints. Stored to ''#{ENV['OUTPUT']}''"
