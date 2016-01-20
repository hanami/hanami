require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Create < Abstract
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.create
        end
      end
    end
  end
end
