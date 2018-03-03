require "morganite"

class Root
  include Stout::Magic
  @@content : String?

  def self.routes(server)
    server.get "/" do |c|
      c << Root.new.render
    end
  end

  def render
    @@content unless @@content.nil?

    @@content =
      Morganite::Morganite.yield {
        html {
          [
            head {
              title { "Welcome to Stout!" }
            },
            body {
              [
                h1 { "Welcome to Stout!" },
              ].join
            },
          ].join
        }
      }
  end
end

class Morganite::Morganite
  def self.yield
    m = Morganite.new
    with m yield
  end
end
