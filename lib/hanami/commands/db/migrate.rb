require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Migrate < Command
        requires 'model.sql'

        def initialize(options, version)
          super(options)
          @version = version
        end

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.migrate(version: version)
        end

        private

        attr_reader :version
      end
    end
  end
end
