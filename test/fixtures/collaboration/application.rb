require 'lotus'

module Collaboration
  class Application < Lotus::Application
    configure do
      layout :application

      routes  'config/routes'
      mapping 'config/mapping'
    end
  end
end
