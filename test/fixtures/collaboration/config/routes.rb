get '/',              to: 'home#index', as: :root
get '/error',         to: 'home#error'
get '/action_legacy', to: 'home#legacy'
get '/protected',     to: 'protected#index'
get '/body',          to: 'rendering#body'
get '/presenter',     to: 'rendering#presenter'
redirect '/legacy',   to: '/'
