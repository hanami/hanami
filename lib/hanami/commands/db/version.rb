require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Version < Command
        requires 'model.configuration'

        # @api private
        def start
          require 'hanami/model/migrator'
          puts Hanami::Model::Migrator.version
        end
      end
    end
  end
end
