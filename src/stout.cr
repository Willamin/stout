require "http/server"
require "ecr"
require "radix"

alias Routes = Radix::Tree(Proc(Stout::Context, Nil))

module Stout
  VERSION = {{ `shards version __DIR__`.chomp.stringify }}

  class Context
    @http : HTTP::Server::Context
    property params : Hash(String, String)

    def initialize(@http, @params); end

    def <<(something)
      @http.response << (something)
    end

    forward_missing_to @http
  end

  class Server
    include HTTP::Handler
    property host = "0.0.0.0"
    property port = 8888
    property routes = {
      get:  Routes.new,
      post: Routes.new,
    }

    def get(path : String, &block : Stout::Context -> Nil)
      routes[:get].add(path, block)
    end

    def listen
      server = HTTP::Server.new(host, port, [
        HTTP::ErrorHandler.new,
        HTTP::LogHandler.new,
        HTTP::CompressHandler.new,
        self,
        HTTP::StaticFileHandler.new("."),
      ])

      puts "Listening on http://#{host}:#{port}"
      server.listen
    end

    def call(context)
      verb = context.request.method
      path = context.request.path

      case verb
      when "get"
        router = routes[:get]
      else
        router = routes[:get]
      end

      result = router.find(path)
      if result.found?
        result.payload.call(Stout::Context.new(context, result.params))
      else
        call_next(context)
      end
    end
  end

  module Magic
    extend self

    macro ecrs(path)
      content = IO::Memory.new
      ECR.embed({{path}}, content)
      content.to_s
    end

    macro t(name)
      Stout::Magic.ecrs("src/template/{{name.id}}.html.ecr")
    end
  end
end
