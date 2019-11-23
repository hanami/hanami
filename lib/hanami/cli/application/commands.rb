# frozen_string_literal: true

require "hanami/cli/registry"

module Hanami
  class CLI
    module Application
      # Hanami application CLI commands registry
      module Commands
        extend Hanami::CLI::Registry

        require_relative "commands/console"
      end
    end
  end
end
