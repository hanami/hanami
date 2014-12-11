module SessionsApp
  class Application < Lotus::Application
    configure do
      sessions :cookie, secret: '1234567890'

      routes do
        post   '/set_session'  , to: 'sessions#create'
        get    '/get_session'  , to: 'sessions#show'
        delete '/clear_session', to: 'sessions#destroy'
      end
    end

    load!
  end


  module Controllers::Sessions
    class Create
      include SessionsApp::Action

      def call(params)
        session[:name] = params[:name]
        self.body = "Session created for: #{session[:name]}"
      end
    end

    class Show
      include SessionsApp::Action

      def call(params)
        self.body = session[:name] || '[empty]'
      end
    end

    class Destroy
      include SessionsApp::Action

      def call(params)
        name = session[:name]
        session.clear
        self.body = "Session cleared for: #{name}"
      end
    end
  end
end
