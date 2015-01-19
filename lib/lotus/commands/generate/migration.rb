require 'lotus/utils/string'
require 'lotus/generators/migration'

module Lotus
  module Commands
    module Generate
      class Migration 
        
        attr_reader :migration_name, :migration_time, :migration_class, :cli, :source, :target

        def initialize(name, environment, cli)
          set_migration_name(name)
          @migration_time = generate_timestamp

          @target = Pathname.new(environment.root)
          @source = Pathname.new(::File.dirname(__FILE__) + '/../../generators/migration/')

          @cli = cli
          
          @command = Lotus::Generators::Migration.new(self)
        end

        def start
          @command.start
        end

        private

        def set_migration_name(name)
          name = Lotus::Utils::String.new(name)
          @migration_name = name.underscore
          @migration_class = name.classify
        end
        
        def generate_timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
