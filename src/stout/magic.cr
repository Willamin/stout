module Stout::Magic
  extend self

  macro ecrs(path)
    content = IO::Memory.new
    ECR.embed({{path}}, content)
    content.to_s
  end

  macro deft
    module Stout::Magic
      macro t(name)
        Stout::Magic.ecrs(\{{__DIR__}} + "/template/" + \{{name}} + ".html.ecr")
      end
    end

    class Stout::Server
      @static_location = \{{__DIR__}} + "/static"
    end
  end
end
