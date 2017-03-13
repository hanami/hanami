require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Create < Command
        requires 'model.configuration'

        # @api private
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.create
        end
      end
    end
  end
end
