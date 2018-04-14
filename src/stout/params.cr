require "http/server"
require "json"

class Stout::Params
  getter context : HTTP::Server::Context

  # params for the route from the radix tree
  getter route_params : Hash(String, String)?

  # params from the post body
  getter post_params : JSON::Any?

  # params from the querystring
  getter get_params : Hash(String, String)?

  def initialize(@context, @route_params)
    case @context.request.method
    when "POST"
      parse_post
    end
  end

  def parse_post
    post_params = Hash(String, JSON::Type).new
    case @context.request.headers["Content-Type"].split(";").map &.strip
    when .includes?("application/x-www-form-urlencoded")
      @context.request.body.try &.gets_to_end.try do |data_string|
        HTTP::Params.parse(data_string) do |key, value|
          post_params[key] = value
        end
      end
      @post_params = JSON::Any.new(post_params)
    when .includes?("multipart/form-data")
      HTTP::FormData.parse(@context.request) do |part|
        post_params[part.name] = part.body.gets_to_end
      end
      @post_params = JSON::Any.new(post_params)
    when .includes?("application/json")
      @context.request.body.try &.gets_to_end.try do |data_string|
        @post_params = JSON.parse(data_string)
      end
    end
  end

  def []?(name : String) : String | JSON::Any | Nil
    route_params.try &.[name]? || post_params.try &.[name]? || nil
  end

  def [](name : String)
    self[name].not_nil!
  end
end
