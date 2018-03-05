require "http/server"
require "ecr"
require "radix"

require "./stout/*"

alias Routes = Radix::Tree(Proc(Stout::Context, Nil))

module Stout
  VERSION = {{ `shards version __DIR__`.chomp.stringify }}
end
