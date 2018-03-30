require "http"
require "file_utils"

class Stout::Server
  include HTTP::Handler
  property static_location = "static"
  property host = "localhost"
  property port = 8888
  property routes = Routes.new
  STOUT_CACHE_DIR = "#{File.dirname(PROGRAM_NAME)}/../.stout-cache"
  KEY_PATH        = "#{STOUT_CACHE_DIR}/server.key"
  CSR_PATH        = "#{STOUT_CACHE_DIR}/server.csr"
  CERT_PATH       = "#{STOUT_CACHE_DIR}/server.crt"

  def get(path : String, &block : Stout::Context -> Nil)
    routes.add("get " + path, block)
  end

  def get(path : String, simple_output : String)
    get(->(c : Stout::Context) { c << (simple_output) })
  end

  def post(path : String, &block : Stout::Context -> Nil)
    routes.add("post " + path, block)
  end

  def post(path : String, simple_output : String)
    post(->(c : Stout::Context) { c << (simple_output) })
  end

  def listen
    unless Dir.exists?(STOUT_CACHE_DIR)
      FileUtils.mkdir_p(STOUT_CACHE_DIR)
    end

    Stout::Fog.fog(KEY_PATH, "key") { `openssl genrsa -out #{KEY_PATH} 1024` }
    Stout::Fog.fog(CSR_PATH, "csr") { `openssl req -new -subj "/CN=#{host}" -key #{KEY_PATH} -out #{CSR_PATH}` }
    Stout::Fog.fog(CERT_PATH, "cert") { `openssl x509 -req -days 365 -in #{CSR_PATH} -signkey #{KEY_PATH} -out #{CERT_PATH}` }

    context = OpenSSL::SSL::Context::Server.new
    context.add_options(OpenSSL::SSL::Options::NO_TLS_V1 | OpenSSL::SSL::Options::NO_TLS_V1_1 | OpenSSL::SSL::Options::NO_SSL_V2 | OpenSSL::SSL::Options::NO_SSL_V3)
    context.ciphers = OpenSSL::SSL::Context::CIPHERS
    context.private_key = KEY_PATH
    context.certificate_chain = CERT_PATH

    server = HTTP::Server.new(host, port, [
      HTTP::ErrorHandler.new,
      HTTP::LogHandler.new,
      HTTP::CompressHandler.new,
      self,
      HTTP::StaticFileHandler.new(static_location, directory_listing: false),
    ])

    puts "Listening on https://#{host}:#{port}"
    server.tls = context
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
