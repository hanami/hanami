require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Create < Abstract
        def start
          require 'lotus/model/migrator'
          Lotus::Model::Migrator.create
        end
      end
    end
  end
end
