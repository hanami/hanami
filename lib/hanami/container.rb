# frozen_string_literal: true

module Hanami
  # Hanami private IoC
  #
  # @since 2.0.0
  class Container
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def self.finalize!
      root = Hanami.root

      begin
        require "dotenv"
      rescue LoadError # rubocop:disable Lint/HandleExceptions
      end
      Dotenv.load(root.join(".env")) if defined?(Dotenv)

      $LOAD_PATH.unshift root.join("lib")
      Hanami::Utils.require!(root.join("lib", "**", "*.rb"))

      require root.join("config", "environment").to_s
      require root.join("config", "action").to_s
      Hanami::Utils.require!(root.join("apps", "**", "*.rb"))
      require root.join("config", "routes").to_s
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize
  end
end
