require 'hanami/utils/class'
require 'hanami/commands/command'

module Hanami
  module Commands
    class DB
      class Console < Command
        requires 'model.sql'

        def initialize(options, name)
          super(options)
          @name = name
        end

        def start
          exec console.connection_string
        end

        private

        attr_reader :name

        def configuration
          Hanami::Components['model.configuration']
        end

        def console
          require 'hanami/model/sql/console'
          Hanami::Model::Sql::Console.new(configuration.url)
        end
      end
    end
  end
end
