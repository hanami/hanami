require 'hanami/cli'
require 'ostruct'

module Hanami
  class Cli
    def self.register(name, command = nil, aliases: [], &blk)
      Commands.register(name, command, aliases: aliases, &blk)
    end

    module Commands
      extend Hanami::Cli::Registry

      class Context < OpenStruct
        def initialize(data)
          data = data.each_with_object({}) do |(k, v), result|
            v = Utils::String.new(v) if v.is_a?(::String)
            result[k] = v
          end

          super(data)
          freeze
        end

        def with(data)
          self.class.new(to_h.merge(data))
        end

        def binding
          super
        end
      end

      require 'hanami/cli/commands/command'
      require 'hanami/cli/commands/assets'
      require 'hanami/cli/commands/console'
      require 'hanami/cli/commands/db'
      require 'hanami/cli/commands/destroy'
      require 'hanami/cli/commands/generate'
      require 'hanami/cli/commands/new'
      require 'hanami/cli/commands/routes'
      require 'hanami/cli/commands/server'
      require 'hanami/cli/commands/version'
    end
  end
end
