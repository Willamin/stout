require "../../src/stout/magic"

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
      nil
    end
  end

  def self.routes(server)
    server.get "/:page" do |c|
      c << Page.find(c.params["page"]).not_nil!.content
    end
  end
end
