require 'hanami/utils/class'
require 'hanami/commands/command'

module Hanami
  module Commands
    # @api private
    class DB
      # @api private
      class Console < Command
        requires 'model.sql'

        # @api private
        def initialize(options, name)
          super(options)
          @name = name
        end

        # @api private
        def start
          exec console.connection_string
        end

        private

        # @api private
        attr_reader :name

        # @api private
        def configuration
          Hanami::Components['model.configuration']
        end

        # @api private
        def console
          require 'hanami/model/sql/console'
          Hanami::Model::Sql::Console.new(configuration.url)
        end
      end
    end
  end
end
