require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Apply < Abstract
        def start
          require 'lotus/model/migrator'
          Lotus::Model::Migrator.apply
        end
      end
    end
  end
end
