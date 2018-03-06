require "http/server"

class Stout::Context
  @http : HTTP::Server::Context
  property params : Hash(String, String)

  def initialize(@http, @params); end

  def <<(something)
    @http.response << (something)
  end

  def call_next
    @http.call_next(@http)
  end

  forward_missing_to @http
end
