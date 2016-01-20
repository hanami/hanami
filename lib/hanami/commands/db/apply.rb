require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Apply < Abstract
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.apply
        end
      end
    end
  end
end
