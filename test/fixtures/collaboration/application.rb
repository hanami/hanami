require 'lotus'

module Collaboration
  class Application < Lotus::Application
    configure do
      root   File.dirname(__FILE__)
      layout :application

      routes  'config/routes'
      mapping 'config/mapping'
    end
  end
end
