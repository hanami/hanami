require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Migrate < Command
        requires 'model.sql'

        # @api private
        def initialize(options, version)
          super(options)
          @version = version
        end

        # @api private
        def start
          require 'hanami/model/migrator'
          Hanami::Model::Migrator.migrate(version: version)
        end

        private

        # @api private
        attr_reader :version
      end
    end
  end
end
