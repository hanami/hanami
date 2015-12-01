get '/',                   to: 'home#index', as: :root
get '/error',              to: 'home#error'
get '/action_legacy',      to: 'home#legacy', as: :legacy
get '/protected',          to: 'protected#index'
get '/body',               to: 'rendering#body'
get '/presenter',          to: 'rendering#presenter'
get '/custom_error',       to: 'custom_error#index'
get '/redirected_routes',  to: 'redirected_routes#index'
get '/assets',             to: 'assets#index'

redirect '/legacy',   to: '/'

resources :books
resources :authors, only: [:create, :update, :destroy]
