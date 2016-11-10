require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Prepare < Command
        requires 'model.sql'

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.prepare
        end
      end
    end
  end
end
