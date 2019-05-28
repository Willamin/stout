require "http/server"
require "http/params"
require "json"

class Stout::Params
  getter context : HTTP::Server::Context

  # params for the route from the radix tree
  getter route_params : Hash(String, String)?

  # params from the post body
  getter post_params : JSON::Any?

  # params from the querystring
  getter get_params : Hash(String, String)?

  @body : String

  def initialize(@context, @body, @route_params)
    case @context.request.method
    when "POST"
      parse_post
    when "GET"
      parse_get
    end
  end

  def parse_get
    get_params = Hash(String, String).new
    @context.request.query_params.each do |k, v|
      get_params[k] = v
    end
    @get_params = get_params
  end

  def parse_post
    post_params = Hash(String, JSON::Any).new
    @context.request.headers["Content-Type"]?.try do |content_types|
      case content_types.split(";").map &.strip
      when .includes?("application/x-www-form-urlencoded")
        HTTP::Params.parse(@body) do |key, value|
          post_params[key] = JSON::Any.new(value)
        end
        @post_params = JSON::Any.new(post_params)
      when .includes?("multipart/form-data")
        HTTP::FormData.parse(@context.request) do |part|
          post_params[part.name] = JSON::Any.new(part.body.gets_to_end)
        end
        @post_params = JSON::Any.new(post_params)
      when .includes?("application/json")
        @post_params = JSON.parse(@body)
      end
    end
  end

  def []?(name : String) : String | JSON::Any | Nil
    route_params.try &.[name]? || post_params.try &.[name]? || get_params.try &.[name]? || nil
  end

  def [](name : String)
    self[name]?.not_nil!
  end
end
