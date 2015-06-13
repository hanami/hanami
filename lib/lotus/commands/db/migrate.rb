require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Migrate < Abstract
        def initialize(environment, version)
          super(environment)
          @version = version
        end

        def start
          require 'lotus/model/migrator'
          Lotus::Model::Migrator.migrate(version: @version)
        end
      end
    end
  end
end
