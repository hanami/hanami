require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Version < Abstract
        def start
          require 'hanami/model/migrator'
          puts Hanami::Model::Migrator.version
        end
      end
    end
  end
end
