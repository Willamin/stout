module Stout::Magic
  macro t(name)
    Stout::Magic.ecrs({{__DIR__}} + "/template/{{name.id}}.html.ecr")
  end
end

require "../src/stout"
require "./model/*"

server = Stout::Server.new

server.get "/" { |c| c << "nothing here. try /hello" }
Page.routes(server)

server.listen
