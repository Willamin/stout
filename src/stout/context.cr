require "http/server"
require "json"

class Stout::Context
  @http : HTTP::Server::Context

  # the globalish list of route names like :user_path
  getter route_names : Hash(Symbol, String)

  # the default route to use if the route name doesn't exist
  getter default_route : String

  # params for the route from the radix tree
  property params : Hash(String, String)

  # params from the body
  getter data : JSON::Any?

  def initialize(@http, @params, @route_names, @default_route)
    if @http.request.method == "POST"
      data = Hash(String, JSON::Type).new
      pp @http.request.headers["Content-Type"]
      case @http.request.headers["Content-Type"].split(";").map &.strip
      when .includes?("application/x-www-form-urlencoded")
        @http.request.body.try &.gets_to_end.try do |data_string|
          HTTP::Params.parse(data_string) do |key, value|
            data[key] = value
          end
        end
        @data = JSON::Any.new(data)
      when .includes?("multipart/form-data")
        HTTP::FormData.parse(@http.request) do |part|
          data[part.name] = part.body.gets_to_end
        end
        @data = JSON::Any.new(data)
      when .includes?("application/json")
        @http.request.body.try &.gets_to_end.try do |data_string|
          @data = JSON.parse(data_string)
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
