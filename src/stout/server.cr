require "http"
require "file_utils"

module Stout
  enum Env
    Development
    Testing
    Production
  end
end

class Stout::Server
  include HTTP::Handler

  STOUT_ENV       = ENV["STOUT_ENV"]?.try { |e| Stout::Env.parse?(e) } || Stout::Env::Development
  STOUT_CACHE_DIR = ENV["STOUT_CACHE"]? || "#{File.dirname(PROGRAM_NAME)}/../.stout-cache"
  KEY_PATH        = ENV["SSL_CERTIFICATE_KEY"]? || "#{STOUT_CACHE_DIR}/server.key"
  CSR_PATH        = ENV["SSL_CERTIFICATE_SIGNER"]? || "#{STOUT_CACHE_DIR}/server.csr"
  CERT_PATH       = ENV["SSL_CERTIFICATE"]? || "#{STOUT_CACHE_DIR}/server.crt"
  HOST            = ENV["HOST"]? || "localhost"
  PORT            = ((ENV["PORT"]?.try &.to_i) || 8888).as Int32

  property static_location = "static"
  property routes = Routes.new
  getter route_names = Hash(Symbol, String).new
  getter default_route : String = "/"
  getter use_ssl = false
  getter reveal_errors = false
  getter use_static = true
  getter rewrites = Hash(String, String).new

  {% for method in %w(get post patch put delete) %}
    def {{method.id}}(path : String, name : Symbol? = nil, &block : Stout::Context -> Nil)
      routes.add("/" + {{method}} + path, block)
      {% if method == "get" %}
        routes.add("/head" + path, block)
      {% end %}
      name.try do |name|
        route_names[name] = path
      end
    end
  {% end %}

  def default_route=(path)
    if default_route.empty?
      @default_route = path
    else
      nil
    end
  end

  def initialize(@use_ssl = false, @reveal_errors = false, @use_static = true); end

  def ssl_context : OpenSSL::SSL::Context::Server
    unless Dir.exists?(STOUT_CACHE_DIR)
      FileUtils.mkdir_p(STOUT_CACHE_DIR)
    end

    if !File.exists?(KEY_PATH)
      if ENV["SSL_CERTIFICATE_KEY"]?
        raise "looking for ssl certificate key in #{KEY_PATH}. couldn't find it."
      end
      `openssl genrsa -out #{KEY_PATH} 2048`
    end

    if !File.exists?(CERT_PATH)
      if ENV["SSL_CERTIFICATE"]?
        raise "looking for ssl certificate in #{CERT_PATH}. couldn't find it."
      end

      if !File.exists?(CSR_PATH)
        if ENV["SSL_CERTIFICATE_SIGNER"]?
          raise "looking for ssl certificate signer in #{CSR_PATH}. couldn't find it."
        end
        `openssl req -new -subj "/CN=#{HOST}" -key #{KEY_PATH} -out #{CSR_PATH}`
      end

      `openssl x509 -req -days 365 -in #{CSR_PATH} -signkey #{KEY_PATH} -out #{CERT_PATH}`

      unless ENV["SSL_CERTIFICATE_SIGNER"]?
        `rm #{CSR_PATH}`
      end
    end

    context = OpenSSL::SSL::Context::Server.new
    context.add_options(OpenSSL::SSL::Options::NO_TLS_V1 | OpenSSL::SSL::Options::NO_TLS_V1_1 | OpenSSL::SSL::Options::NO_SSL_V2 | OpenSSL::SSL::Options::NO_SSL_V3)
    # context.ciphers = OpenSSL::SSL::Context::CIPHERS
    context.private_key = KEY_PATH
    context.certificate_chain = CERT_PATH
    context
  end

  def listen
    handler_list = [] of HTTP::Handler
    handler_list << HTTP::ErrorHandler.new
    handler_list << HTTP::LogHandler.new
    handler_list << HTTP::CompressHandler.new
    handler_list << self
    if use_static
      handler_list << HTTP::StaticFileHandler.new(static_location, directory_listing: false)
    end

    server = HTTP::Server.new(handler_list)

    listen_message!("http")

    if use_ssl
      server.bind_ssl(HOST, PORT, ssl_context)
    else
      server.listen(HOST, PORT)
    end
  end

  def listen_message!(protocol : String)
    if use_ssl
      protocol = "#{protocol}s"
    end
    puts "Listening on #{protocol}://#{HOST}:#{PORT}"
  end

  def rewrite(path, new_path)
    rewrites[path] = new_path
  end

  def call(context)
    verb = context.request.method.downcase
    path = context.request.path

    previously_rewritten = [] of String
    while new_path = rewrites[path]?
      if previously_rewritten.includes?(path)
        path = previously_rewritten[0]
        break
      end
      previously_rewritten << path

      puts "#{path} -> #{new_path}"

      path = new_path
    end
    context.request.path = path

    route = "/" + verb + path

    result = routes.find(route)

    if result.found?
      begin
        result.payload.call(Stout::Context.new(context, result.params, route_names, default_route))
      rescue e
        if reveal_errors
          context.response << e.inspect
          puts e.inspect
        else
          raise e
        end
      end
    else
      call_next(context)
    end
  rescue
    call_next(context)
  end
end
