module Lint
  class Application < Hanami::Application
    configure do
      routes do
        get '/',         to: 'home#index'
        get '/greet',    to: 'home#greet'
        get '/download', to: 'home#download'
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

    # This is an integration test case for `Action#renderable?`.
    # Please have a look at `Hanami::Action::Glue` and `#send_file`.
    class Download
      include Lint::Action

      def call(params)
        send_file __FILE__
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
