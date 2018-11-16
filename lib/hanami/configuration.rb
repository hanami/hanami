# frozen_string_literal: true

require "concurrent/hash"

module Hanami
  # Hanami application configuration
  #
  # @since 2.0.0
  class Configuration
    def initialize
      @settings = Concurrent::Hash.new
      self.routes = DEFAULT_ROUTES
    end

    def routes=(value)
      settings[:routes] = value
    end

    def routes
      settings.fetch(:routes)
    end

    private

    DEFAULT_ROUTES = File.join("config", "routes")
    private_constant :DEFAULT_ROUTES

    attr_reader :settings
  end
end
