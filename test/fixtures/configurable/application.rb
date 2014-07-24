module Configurable
  class Application < Lotus::Application
    configure do
      handle_exceptions false

      routes do
        get '/error', to: 'error#index'
      end
    end

    load!
  end

  module Controllers::Error
    include Configurable::Controller

    action 'Index' do
      def call(params)
        raise ArgumentError
      end
    end
  end
end
