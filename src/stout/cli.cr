module Stout::Cli
  extend self

  def flag?(flags : Array(String))
    !(ARGV & flags).empty?
  end

  def flag?(flag : String)
    flag?([flag])
  end

  def draw_route_tree(tree, level = 0)
    s = "  " * level + tree.key + "\n"
    tree.children.each do |c|
      s += draw_route_tree(c, level + 1)
    end
    s
  end

  def draw_route_list(tree, parents = "") : String
    if tree.children.size > 0
      list = [] of String
      tree.children.each do |c|
        list << draw_route_list(c, parents + tree.key)
      end
      list.join
    else
      parents + tree.key + "\n"
    end
  end

  def handle(server)
    if flag?("routetree")
      puts draw_route_tree(server.routes.root)
    end

    if flag?("routelist")
      puts
      draw_route_list(server.routes.root).each_line do |line|
        print sprintf("%-7s", line[1..-1].split("/")[0].upcase)
        print " /"
        puts line[1..-1].split("/")[1..-1].join("/")
      end
      puts
    end
  end
end
