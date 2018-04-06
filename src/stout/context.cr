require "http/server"

class Stout::Context
  @http : HTTP::Server::Context

  # the globalish list of route names like :user_path
  getter route_names : Hash(Symbol, String)

  # the default route to use if the route name doesn't exist
  getter default_route : String

  # params for the route from the radix tree
  property params : Hash(String, String)

  # params from the body
  getter data : Hash(String, String)

  def initialize(@http, @params, @route_names, @default_route)
    @data = Hash(String, String).new
    if @http.request.method == "POST"
      @http.request.body.try do |body|
        body.as(IO).gets_to_end.split("&").each do |r|
          k, v = r.split("=")
          @data[k] ||= URI.unescape(v)
        end
      end
    end
  end

  def <<(something)
    @http.response << (something)
  end

  def call_next
    @http.call_next(@http)
  end

  def path(name : Symbol) : String
    route_names[name]? || default_route
  end

  forward_missing_to @http
end
