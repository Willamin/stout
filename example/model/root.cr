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
              [
                title { "Welcome to Stout!" },
                link(rel: "stylesheet", href: "/clean.css"),
                link(rel: "stylesheet", href: "/app.css"),
              ].join
            },
            body {
              [
                div class: "navbar container" {
                  [
                    h1 { "Welcome to Stout!" },
                  ].join
                },
                div class: "main container" {
                  div {
                    [
                      h1 { "Stout" },
                      p { "<em>A web application framework designed with stout models in mind.</em>" },
                      p { "What's a stout model? It's a framework pattern in which models hold as much as they can." },
                      p { "What do Stout's models handle?" },
                      ul { [
                        li { "business logic" },
                        li { "defining their relevant routes" },
                        li { "controller-ish actions" },
                        li { "rendering" },
                        li { "all of the other things!" },
                      ].join },
                      p { "If that's too much for <em>you</em>, never fear! You can still use Stout! Because it's an opinionated, but <em>flexible</em> framework, you can:" },
                      ul { [
                        li { "define your routes outside of the models" },
                        li { "write as many controllers, controller factories, and controller factory builders as your heart desires" },
                        li { "use ecr template files! (no disappointed glances for doing this, seriously!)" },
                      ].join },
                    ].join
                  }
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
