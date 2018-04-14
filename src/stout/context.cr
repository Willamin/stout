require "http/server"
require "./params"

class Stout::Context
  @http : HTTP::Server::Context

  # the globalish list of route names like :user_path
  getter route_names : Hash(Symbol, String)

  # the default route to use if the route name doesn't exist
  getter default_route : String

  getter params : Stout::Params

  def initialize(@http, route_params, @route_names, @default_route)
    @params = Stout::Params.new(@http, route_params)
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
