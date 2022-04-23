# frozen_string_literal: true

Hanami.application.register_provider :helpers do
  start do
    begin
      require "hanami/application/helpers"
    rescue LoadError
    end

    return unless defined?(Hanami::Application::Helpers)

    register :helpers, Hanami::Application::Helpers.new
  end
end
