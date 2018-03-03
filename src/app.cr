require "./stout"
require "./model/*"

server = Stout::Server.new

server.get "/" { |c| c << "nothing here. try /hello" }
Page.routes(server)

server.listen
