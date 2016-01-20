module Configurable
  module Authentication
    private
    def authenticate!
      self.body = 'authenticated'
    end
  end

  class Application < Hanami::Application
    configure do
      handle_exceptions false

      routes do
        get '/error', to: 'error#index'
        get '/twist', to: 'twist#index'
      end

      model.adapter type: :memory, uri: 'memory://localhost'
      model.mapping { }

      controller.default_request_format :xml
      controller.default_response_format :json
      controller.default_charset 'koi8-r'
      controller.prepare do
        include Authentication
        before :authenticate!
      end

      view.root Dir.pwd
    end

    load!
  end

  module Controllers::Error
    class Index
      include Configurable::Action

      def call(params)
        raise ArgumentError
      end
    end
  end

  module Controllers::Twist
    class Index
      include Configurable::Action

      def call(params)
      end
    end
  end
end
