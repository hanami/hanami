require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Version < Command
        requires 'model.configuration'

        def start
          require 'hanami/model/migrator'
          puts Hanami::Model::Migrator.version
        end
      end
    end
  end
end
