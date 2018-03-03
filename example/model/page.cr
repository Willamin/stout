class Page
  include Stout::Magic

  property slug : String
  property content : String

  def initialize(@slug, @content); end

  def self.find(slug)
    case slug
    when "hello"
      Page.new(slug, t("hello"))
    else
      Page.new(slug, "not found")
    end
  end

  def self.routes(server)
    server.get "/:page" { |c|
      c << Page.find(c.params["page"]).content
    }
  end
end
