require 'hanami/commands/db/abstract'

module Hanami
  module Commands
    class DB
      class Prepare < Abstract
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.prepare
        end
      end
    end
  end
end
