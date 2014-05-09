module CoffeeShop
  class Application < Lotus::Application
    configure do
      root __dir__

      routes do
        get '/', to: ->{}
      end
    end
  end
end
