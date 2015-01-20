require 'thor'
require 'lotus/environment'


module Lotus
  class Generate < Thor
    include Thor::Actions

    desc 'migration [SLICE] NAME', 'generates a model migration'
    def migration(*names)
      if options[:help] || names.empty? || names.length > 2
        invoke :help, ['migration']
      else
        require 'lotus/commands/generate/migration'
        Lotus::Commands::Generate::Migration.new(names, environment, self).start
      end
    end

    private

    def environment
      Lotus::Environment.new(options)
    end
  end
end
