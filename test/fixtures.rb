class Customer
end

module CoffeeShop
  class Application < Lotus::Application
    configure do
      root   File.dirname(__FILE__)
      layout nil

      load_paths.clear

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
