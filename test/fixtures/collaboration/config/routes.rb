get '/',              to: 'home#index', as: :root
get '/error',         to: 'home#error'
get '/action_legacy', to: 'home#legacy'
redirect '/legacy',   to: '/'
