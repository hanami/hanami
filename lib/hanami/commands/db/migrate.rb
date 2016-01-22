require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Migrate < Abstract
        def initialize(environment, version)
          super(environment)
          @version = version
        end

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.migrate(version: @version)
        end
      end
    end
  end
end
