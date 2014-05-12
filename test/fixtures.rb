# FIXME move this into CoffeeShop module
class ApplicationLayout
end

class Customer
end

module CoffeeShop
  class Application < Lotus::Application
    configure do
      root __dir__

      loading_paths.clear

      routes do
        get '/', to: ->{}, as: :root
      end

      mapping do
        collection :customers do
          entity Customer
        end
      end
    end
  end
end
