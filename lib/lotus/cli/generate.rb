require 'thor'
require 'lotus/environment'


module Lotus
  class Generate < Thor
    include Thor::Actions
    desc 'migration NAME', 'generates a model migration'
    def migration(name = nil)
      if options[:help] || name.nil?
        invoke :help, ['migration']
      else
        require 'lotus/commands/generate/migration'
        Lotus::Commands::Generate::Migration.new(name, environment, self).start
      end
    end

    private

    def environment
      Lotus::Environment.new(options)
    end
  end
end
