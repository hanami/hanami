require 'hanami/cli'
require 'ostruct'
require 'erb'

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

        def binding
          super
        end
      end

      class Renderer
        TRIM_MODE = "-".freeze

        def call(template, context)
          ::ERB.new(template, nil, TRIM_MODE).result(context)
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
