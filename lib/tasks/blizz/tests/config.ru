require './server.rb'
require './tests.rb'

main

run Rack::URLMap.new({
                       "/" => TestAPI,
                       "/protected" => TestAuth
                     })
