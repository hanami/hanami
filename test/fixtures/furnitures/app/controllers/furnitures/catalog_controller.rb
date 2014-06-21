module Furnitures::CatalogController
  include Furnitures::Controller

  action 'Index' do
    def call(params)
    end
  end

  action 'Error' do
    def call(params)
      raise 'boom'
    end
  end

  action 'Legacy' do
    def call(params)
      redirect_to 'http://localhost/catalog'
    end
  end

  action 'Protected' do
    def call(params)
      halt 401
    end
  end
end
