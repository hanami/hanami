require 'lotus'

module InformationTech
  class Application < Lotus::Application
    configure do
      namespace Object

      controller_pattern '%{controller}Controller::%{action}'
      view_pattern       '%{controller}::%{action}'

      load_paths << 'app'

      layout :app

      serve_assets true

      assets << [
        'public'
      ]

      routes do
        get '/hardware',      to: 'hardware#index'
        get '/error',         to: 'hardware#error'
        get '/action_legacy', to: 'hardware#legacy'
        get '/protected',     to: 'hardware#protected'

        redirect '/legacy',   to: '/hardware'
      end
    end
  end
end
