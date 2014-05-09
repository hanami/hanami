module CoffeeShop
  class Application < Lotus::Application
    configure do
      root __dir__

      routes do
        get '/', to: ->{}
      end

      mapping do
        collection :customers do
        end
      end
    end
  end
end
