module Magazine
  class Application < Lotus::Application
    configure do
      root __dir__

      routes do
        get '/', to: 'articles#index'
      end
    end
  end
end
