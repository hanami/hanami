module CustomErrorTemplates
  class Application < Lotus::Application
    configure do
      routes do
        get '/not_found', to: 'home#not_found'
        get '/internal_server_error', to: 'home#internal_server_error'
        get '/unprocessable_entity', to: 'home#unprocessable_entity'
      end
    end

    load!
  end

  module Controllers
    module Home
      include CustomErrorTemplates::Controller

      action 'NotFound' do
        def call(params)
          halt 404
        end
      end

      action 'InternalServerError' do
        def call(params)
          halt 500
        end
      end

      action 'UnprocessableEntity' do
        def call(params)
          halt 422
        end
      end
    end
  end
end