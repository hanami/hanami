# frozen_string_literal: true

require "concurrent/hash"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  class Configuration
    require "hanami/configuration/sessions"

    def initialize
      @settings = Concurrent::Hash.new
      self.routes = DEFAULT_ROUTES
      self.sessions = DEFAULT_SESSIONS
    end

    def routes=(value)
      settings[:routes] = value
    end

    def routes
      settings.fetch(:routes)
    end

    def sessions=(*args)
      settings[:sessions] = Sessions.new(args)
    end

    def sessions
      settings.fetch(:sessions)
    end

    private

    DEFAULT_ROUTES = File.join("config", "routes")
    private_constant :DEFAULT_ROUTES

    DEFAULT_SESSIONS = Sessions.null
    private_constant :DEFAULT_SESSIONS

    attr_reader :settings
  end
end
