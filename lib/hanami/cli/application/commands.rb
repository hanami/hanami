# frozen_string_literal: true

require "dry/cli/registry"

module Hanami
  class CLI
    module Application
      # Hanami application CLI commands registry
      module Commands
        extend Dry::CLI::Registry

        require_relative "commands/console"
      end
    end
  end
end
