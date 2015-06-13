require 'lotus/commands/db/abstract'

module Lotus
  module Commands
    class DB
      class Prepare < Abstract
        def start
          require 'lotus/model/migrator'
          Lotus::Model::Migrator.prepare
        end
      end
    end
  end
end
