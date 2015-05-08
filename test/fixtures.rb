require 'lotus/model'

class Order
  include Lotus::Entity

  attributes :size, :coffee, :qty
end

class OrderRepository
  include Lotus::Repository
end

module CoffeeShop
  class Application < Lotus::Application
    configure do
      root   Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop')
      layout nil

      load_paths.clear
      templates 'app/templates'

      scheme 'https'
      host   'lotus-coffeeshop.org'

      routes do
        get '/', to: ->{}, as: :root
      end

      adapter type: :memory, uri: 'memory://localhost'
      mapping do
        collection :orders do
          entity Order

          attribute :id,     Integer
          attribute :size,   String
          attribute :coffee, String
          attribute :qty,    Integer
        end
      end
    end
  end
end

module Reviews
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: ->{}, as: :root
      end
    end
  end
end

class RackApp
  def self.call(env)
    [200, {}, ['Hello from RackApp']]
  end
end

module Backend
  class App
    def self.call(env)
    [200, {}, ['home']]
    end
  end
end

class TinyApp < Lotus::Application
  configure do
    routes do
      get '/', to: 'home#index'
    end
  end
end
