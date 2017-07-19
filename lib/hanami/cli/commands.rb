require 'hanami/cli'
require 'ostruct'

module Hanami
  module Cli
    include Hanami::Cli::Mixin

    module Commands
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
