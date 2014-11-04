require 'lotus'

module Collaboration
  class Application < Lotus::Application
    configure do
      layout :application

      load_paths << 'app'

      assets << ['vendor', 'public']
      routes  'config/routes'
      mapping 'config/mapping'
    end
  end
end
