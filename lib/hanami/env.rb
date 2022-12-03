# frozen_string_literal: true

module Hanami
  module Env
    # @since 2.0.1
    # @api private
    @_loaded = false

    # Uses [dotenv](https://github.com/bkeepers/dotenv) (if available) to populate `ENV` from
    # various `.env` files.
    #
    # For a given `HANAMI_ENV` environment, the `.env` files are looked up in the following order:
    #
    # - .env.{environment}.local
    # - .env.local (unless the environment is `test`)
    # - .env.{environment}
    # - .env
    #
    # If dotenv is unavailable, the method exits and does nothing.
    #
    # @since 2.0.1
    # @api private
    def self.load(env = Hanami.env)
      return unless Hanami.bundled?("dotenv")
      return if loaded?

      dotenv_files = [
        ".env.#{env}.local",
        (".env.local" unless env == :test),
        ".env.#{env}",
        ".env"
      ].compact

      require "dotenv"
      Dotenv.load(*dotenv_files)

      loaded!
    end

    # @since 2.0.1
    # @api private
    def self.loaded?
      @_loaded
    end

    # @since 2.0.1
    # @api private
    def self.loaded!
      @_loaded = true
    end
  end
end
