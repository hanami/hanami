require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Drop < Abstract
        def start
          require 'lotus/model/migrator'
          Lotus::Model::Migrator.drop
        end
      end
    end
  end
end
