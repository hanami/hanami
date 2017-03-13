require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Apply < Command
        requires 'model.sql'

        # @api private
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.apply
        end
      end
    end
  end
end
