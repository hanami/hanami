require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Prepare < Command
        requires 'model.sql'

        # @api private
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.prepare
        end
      end
    end
  end
end
