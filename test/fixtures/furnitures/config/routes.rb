get '/catalog',       to: 'catalog#index'
get '/error',         to: 'catalog#error'
get '/action_legacy', to: 'catalog#legacy'
get '/protected',     to: 'catalog#protected'

redirect '/legacy',   to: '/catalog'
