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
  end
end
