module Furnitures::CatalogController
  class Index
    include Furnitures::Action

    def call(params)
    end
  end

  class Error
    include Furnitures::Action

    def call(params)
      raise 'boom'
    end
  end

  class Legacy
    include Furnitures::Action

    def call(params)
      redirect_to 'http://localhost/catalog'
    end
  end

  class Protected
    include Furnitures::Action

    def call(params)
      halt 401
    end
  end
end
