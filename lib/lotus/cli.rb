require 'thor'
require 'lotus/commands/server'

module Lotus
  class Cli < Thor
    desc "server", "starts a lotus server"
    def server
      Lotus::Commands::Server.new.start
    end
  end
end
