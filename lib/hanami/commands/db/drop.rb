require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Drop < Command
        requires 'model.configuration'

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.drop
        end
      end
    end
  end
end
