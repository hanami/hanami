module CoffeeShop

  class User
    include Lotus::Entity
    self.attributes = :name, :age
  end

  class UserRepository
    include Lotus::Repository
  end

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
        resources :users
      end

      mapping do
        collection :users do
          entity User

          attribute :id,   Integer
          attribute :name, String
          attribute :age,  Integer
        end
      end
    end
  end
end
