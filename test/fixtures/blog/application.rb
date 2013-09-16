module Blog
  class Application < Lotus::Application
    configure do
      root __dir__

      routes do
        get '/',      to: 'posts#index'
        get '/raise', to: 'posts#raise'
      end
    end
  end
end
