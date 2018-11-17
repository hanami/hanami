# frozen_string_literal: true

require "hanami"
require "rack"

module Hanami
  # Rack compatible server.
  #
  # It is run with:
  #
  #   `bundle exec hanami server`
  #
  # It runs the application, by using the server specified in your `Gemfile`
  # (eg. Puma or Unicorn).
  #
  # @since 0.8.0
  # @api private
  class Server < ::Rack::Server
    # @api private
    attr_reader :options

    # @since 0.8.0
    # @api private
    #
    # @see Hanami::Environment#initialize
    def initialize
      @options = _extract_options
    end

    # Primarily this removes the ::Rack::Chunked middleware
    # which is the cause of Safari content-length bugs.
    #
    # @since 0.8.0
    def middleware
      mw = Hash.new { |e, m| e[m] = [] }
      mw["development"].concat([::Rack::ShowExceptions, ::Rack::Lint])
      mw
    end

    def start
      Hanami.boot
      super
    end

    private

    # Options for Rack::Server superclass
    #
    # @since 0.8.0
    # @api private
    def _extract_options
      # TODO: use default options from container
      # TODO: merge with options from CLI
      {
        config: "config.ru",
        Host: "0.0.0.0",
        Port: "2300",
        AccessLog: []
      }
    end
  end
end
