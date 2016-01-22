module Frontend
  class Application < Hanami::Application
    configure do
      root File.dirname(__FILE__)
      load_paths << [
        'controllers',
        'views'
      ]

      layout :frontend

      assets do
        sources << [
          'vendor/assets'
        ]
      end

      routes do
        resource :sessions, only: [:new]
      end
    end
  end
end
