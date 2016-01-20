module Backend
  class Application < Hanami::Application
    configure do
      root File.dirname(__FILE__)
      load_paths << [
        'controllers',
        'views'
      ]

      layout :backend

      routes do
        resource :sessions, only: [:new]
      end
    end
  end
end
