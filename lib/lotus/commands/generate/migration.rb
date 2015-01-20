require 'lotus/utils/string'
require 'lotus/generators/migration'

module Lotus
  module Commands
    module Generate
      class Migration 
        
        attr_reader :migration_name, :migration_time, :migration_class, :cli, :source, :target

        def initialize(names, environment, cli)
          set_migration_name(names.pop)
          @migration_time = generate_timestamp

          @target = set_target_path(environment, names.pop)
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

        def set_target_path(environment, slice = nil)
          target = Pathname.new(environment.root)
          if slice
            target = target.join("apps/#{slice}")
          end
          target
        end
        
        def generate_timestamp
          Time.now.strftime("%Y%m%d%H%M%S")
        end
      end
    end
  end
end
