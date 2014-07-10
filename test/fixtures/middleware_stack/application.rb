module MiddlewareStack
  class Application < Lotus::Application
    configure do
      # Testing disabled assets, which doesn't include Rack::Static
      assets :disabled

      # Test lazy loading with relative class name
      middleware.use 'Middlewares::Runtime'

      # Test lazy loading with absolute class name and arguments
      middleware.use 'MiddlewareStack::Middlewares::Custom', 'OK'

      # Test already loaded middleware
      middleware.use ::Rack::ETag

      routes do
        get '/', to: 'home#index'
      end
    end

    load!
  end

  module Middlewares
    class Runtime
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        headers['X-Runtime']  = '50ms'

        [status, headers, body]
      end
    end

    class Custom
      def initialize(app, value)
        @app   = app
        @value = value
      end

      def call(env)
        status, headers, body = @app.call(env)
        headers['X-Custom']   = @value

        [status, headers, body]
      end
    end
  end

  module Controllers::Home
    include MiddlewareStack::Controller

    action 'Index' do
      def call(params)
        self.body = 'Hello'
      end
    end
  end
end
