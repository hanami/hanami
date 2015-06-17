require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Version < Abstract
        def start
          require 'lotus/model/migrator'
          puts Lotus::Model::Migrator.version
        end
      end
    end
  end
end
