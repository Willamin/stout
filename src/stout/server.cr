require "http"
require "file_utils"

class Stout::Server
  include HTTP::Handler
  property static_location = "static"
  property host = "localhost"
  property port = 8888
  property routes = Routes.new
  getter route_names = Hash(Symbol, String).new
  getter default_route : String = "/"
  getter use_ssl = false
  getter reveal_errors = false
  STOUT_CACHE_DIR = "#{File.dirname(PROGRAM_NAME)}/../.stout-cache"
  KEY_PATH        = ENV["SSL_CERTIFICATE_KEY"]? || "#{STOUT_CACHE_DIR}/server.key"
  CSR_PATH        = ENV["SSL_CERTIFICATE_SIGNER"]? || "#{STOUT_CACHE_DIR}/server.csr"
  CERT_PATH       = ENV["SSL_CERTIFICATE"]? || "#{STOUT_CACHE_DIR}/server.crt"

  {% for method in %w(get post) %}

    def {{method.id}}(path : String, name : Symbol? = nil, &block : Stout::Context -> Nil)
      routes.add("/" + {{method}} + path, block)
      name.try do |name|
        route_names[name] = path
      end
    end

    def {{method.id}}(path : String, output : String, name : Symbol? = nil)
      {{method.id}}(path, ->(c : Stout::Context) { c << (simple_output) }, name)
    end

  {% end %}

  def default_route=(path)
    if default_route.empty?
      @default_route = path
    else
      nil
    end
  end

  def initialize(@use_ssl = false, @reveal_errors = false); end

  def ssl_context
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
        `openssl req -new -subj "/CN=#{host}" -key #{KEY_PATH} -out #{CSR_PATH}`
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
    server = HTTP::Server.new(host, port, [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      HTTP::CompressHandler.new,
      self,
      HTTP::StaticFileHandler.new(static_location, directory_listing: false),
    ])

    protocol = "http"
    if use_ssl
      protocol = "#{protocol}s"
      server.tls = ssl_context
    end

    puts "Listening on #{protocol}://#{host}:#{port}"
    server.listen
  end

  def call(context)
    verb = context.request.method.downcase
    path = context.request.path

    route = "/" + verb + path
    result = routes.find(route)

    if result.found?
      begin
        result.payload.call(Stout::Context.new(context, result.params, route_names, default_route))
      rescue e
        if reveal_errors
          context << e.inspect
          puts e.inspect
        end
      end
    else
      call_next(context)
    end
  rescue
    call_next(context)
  end
end
