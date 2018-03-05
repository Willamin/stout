require "morganite"
require "markdown"

alias M = Morganite::Morganite

class Root
  include Stout::Magic

  @@content : String?

  def self.routes(server)
    server.get "/" do |c|
      c << Root.new.render
    end
  end

  def navbar
    M.new.div class: "navbar container" { yield }
  end

  def render
    @@content unless @@content.nil?

    begin
      file = File.read({{__DIR__}} + "/../../README.md")
      markdown = Markdown.to_html(file)
    rescue e
      puts e
    end

    @@content =
      M.yield {
        html {
          [
            head {
              [
                title { "Welcome to Stout!" },
                link(rel: "stylesheet", href: "/clean.css"),
                link(rel: "stylesheet", href: "/app.css"),
              ].join
            },
            body {
              [
                navbar {
                  [
                    h1 { "Welcome to Stout!" },
                  ].join
                },
                div class: "main container" {
                  div { markdown }
                },
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
