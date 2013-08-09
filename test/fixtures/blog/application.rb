module Blog
  class Application < Lotus::Application
    configure do
      root __dir__

      routes do
        get '/', to: 'posts#index'
      end
    end
  end
end
