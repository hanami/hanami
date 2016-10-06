require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Create < Command
        requires 'model.configuration'

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.create
        end
      end
    end
  end
end
