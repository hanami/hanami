begin
  require 'dotenv/parser'
rescue LoadError # rubocop:disable Lint/HandleExceptions
end

module Hanami
  # Encapsulate access to ENV
  #
  # @since 0.9.0
  # @api private
  class Env
    # Create a new instance
    #
    # @param env [#[],#[]=] a Hash like object. It defaults to ENV
    #
    # @return [Hanami::Env]
    #
    # @since 0.9.0
    # @api private
    def initialize(env: ENV)
      @env = env
    end

    # Return a value, if found
    #
    # @param key [String] the key
    #
    # @return [String,NilClass] the value, if found
    #
    # @since 0.9.0
    # @api private
    def [](key)
      @env[key]
    end

    # Sets a value
    #
    # @param key [String] the key
    # @param value [String] the value
    #
    # @since 0.9.0
    # @api private
    def []=(key, value)
      @env[key] = value
    end

    # Loads a dotenv file and updates self
    #
    # @param path [String, Pathname] the path to the dotenv file
    #
    # @return void
    #
    # @since 0.9.0
    # @api private
    def load!(path)
      return unless defined?(Dotenv::Parser)

      contents = ::File.open(path, "rb:bom|utf-8", &:read)
      parsed   = Dotenv::Parser.call(contents)

      parsed.each do |k, v|
        next if @env.has_key?(k)

        @env[k] = v
      end
      nil
    end
  end
end
