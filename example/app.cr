require "../src/stout"
Stout::Magic.deft

require "./model/*"

server = Stout::Server.new

server.get "/" { |c| c << "nothing here. try /hello" }
Page.routes(server)

server.listen
