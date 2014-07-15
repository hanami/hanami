module CookiesApp
  class Application < Lotus::Application
    configure do
      # Activate Cookies
      cookies true

      routes do
        get '/get_cookies',              to: 'cookies#get'
        get '/set_cookies',              to: 'cookies#set'
        get '/set_cookies_with_options', to: 'cookies#set_with_options'
        get '/del_cookies',              to: 'cookies#del'
      end
    end

    load!
  end


  module Controllers::Cookies
    include CookiesApp::Controller

    action 'Get' do
      def call(params)
        self.body = cookies[:foo]
      end
    end

    action 'Set' do
      def call(params)
        self.body = 'yummy!'
        cookies[:foo] = 'nomnomnom!'
      end
    end

    action 'SetWithOptions' do
      def call(params)
        self.body = 'with options!'
        expire_date = Time.parse params[:expires]

        cookies[:foo] = {
          value: 'nomnomnom!',
          domain: 'lotusrocks.com',
          path: '/controller',
          expires: expire_date,
          secure: true,
          httponly: true
        }
      end
    end

    action 'Del' do
      def call(params)
        self.body = 'deleted!'
        cookies[:delete] = nil
      end
    end
  end

end
