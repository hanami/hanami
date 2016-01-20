require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Drop < Abstract
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.drop
        end
      end
    end
  end
end
