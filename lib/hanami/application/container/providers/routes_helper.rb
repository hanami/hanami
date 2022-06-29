# frozen_string_literal: true

Hanami.application.register_provider :routes_helper do
  start do
    require "hanami/application/routes_helper"

    register :routes_helper, Hanami::Application::RoutesHelper.new(-> { Hanami.application.router })
  end
end
