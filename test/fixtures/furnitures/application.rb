require 'lotus'

module Furnitures
  class Application < Lotus::Application
    configure do
      layout :application
      routes 'config/routes'

      controller_pattern "%{controller}Controller::%{action}"
      view_pattern       "%{controller}::%{action}"
    end
  end
end
