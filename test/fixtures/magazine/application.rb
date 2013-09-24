module Magazine
  class Application < Lotus::Application
    configure do
      root __dir__
      excluded_load_paths /(features|spec|vendor)/

      routes do
        get '/', to: 'articles#index'
      end
    end
  end
end
