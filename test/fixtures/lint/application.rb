module Lint
  class Application < Lotus::Application
    configure do
      routes do
        get '/',      to: 'home#index'
        get '/greet', to: 'home#greet'
      end
    end

    load!
  end

  module Controllers::Home
    class Index
      include Lint::Action

      def call(params)
      end
    end

    class Greet
      include Lint::Action

      def call(params)
        self.body = 'Hello'
      end
    end
  end

  module Views::Home
    class Index
      include Lint::View

      def render
        'View'
      end
    end
  end
end
