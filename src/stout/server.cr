require "http"

class Stout::Server
  include HTTP::Handler
  property static_location = "static"
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
      HTTP::StaticFileHandler.new(static_location, directory_listing: false),
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
  rescue
    call_next(context)
  end
end
