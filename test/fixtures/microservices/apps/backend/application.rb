module Backend
  class Application < Lotus::Application
    configure do
      root File.dirname(__FILE__)
      load_paths << [
        'controllers',
        'views'
      ]

      serve_assets true

      assets << [
        'public'
      ]

      layout :backend

      routes do
        resource :sessions, only: [:new]
      end
    end
  end
end
