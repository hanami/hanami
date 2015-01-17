require 'lotus/utils/string'
require 'lotus/generators/migration'

module Lotus
  module Commands
    module Generate
      class Migration 
        
        attr_reader :app_name, :migration_name, :migration_time, :migration_class, :cli, :source, :target

        def initialize(name, environment, cli)
          name = Lotus::Utils::String.new(name)
          #@app_name = ""
          @migration_name = name.underscore
          @migration_time = Time.now.to_i.to_s
          @migration_class = name.classify

          @target = Pathname.new(environment.root)
          @source = Pathname.new(::File.dirname(__FILE__) + '/../../generators/migration/')

          @cli = cli
          
          @command = Lotus::Generators::Migration.new(self)
        end

        def start
          @command.start
        end
      end
    end
  end
end
