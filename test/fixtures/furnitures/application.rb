require 'hanami'

module Furnitures
  class Application < Hanami::Application
    configure do
      layout :application
      routes 'config/routes'

      load_paths << 'app'

      controller_pattern "%{controller}Controller::%{action}"
      view_pattern       "%{controller}::%{action}"
    end
  end
end
