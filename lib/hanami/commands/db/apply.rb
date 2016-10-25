require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Apply < Command
        requires 'model.configuration'

        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.apply
        end
      end
    end
  end
end
