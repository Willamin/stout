require "../src/stout"
Stout::Magic.deft

require "./model/*"

server = Stout::Server.new

Root.routes(server)
Page.routes(server)

server.listen
