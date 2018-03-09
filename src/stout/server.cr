require "http"

class Stout::Server
  include HTTP::Handler
  property static_location = "static"
  property host = "0.0.0.0"
  property port = 8888
  property routes = Routes.new

  def get(path : String, &block : Stout::Context -> Nil)
    routes.add("get " + path, block)
  end

  def get(path : String, simple_output : String)
    simple_proc = ->(c : Stout::Context) { c << (simple_output) }
    routes.add("get " + path, simple_proc)
  end

  def listen
    server = HTTP::Server.new(host, port, [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      HTTP::CompressHandler.new,
      self,
      HTTP::StaticFileHandler.new(static_location, directory_listing: false),
    ])

    puts "Listening on http://#{host}:#{port}"
    server.listen
  end

  def call(context)
    verb = context.request.method.downcase
    path = context.request.path

    route = verb + " " + path

    result = routes.find(route)

    if result.found?
      result.payload.call(Stout::Context.new(context, result.params))
    else
      call_next(context)
    end
  rescue
    call_next(context)
  end
end
