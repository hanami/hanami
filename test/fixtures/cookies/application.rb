module CookiesApp
  class Application < Hanami::Application
    configure do
      # Activate Cookies
      cookies domain: 'hanamirb.org', path: '/another_controller', secure: true

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
    class Get
      include CookiesApp::Action

      def call(params)
        self.body = cookies[:foo]
      end
    end

    class Set
      include CookiesApp::Action

      def call(params)
        self.body = 'yummy!'
        cookies[:foo] = 'nomnomnom!'
      end
    end

    class SetWithOptions
      include CookiesApp::Action

      def call(params)
        self.body = 'with options!'
        expire_date = Time.parse params[:expires]

        cookies[:foo] = {
          value: 'nomnomnom!',
          domain: 'hanamirocks.com',
          path: '/controller',
          expires: expire_date,
          secure: true,
          httponly: true
        }
      end
    end

    class Del
      include CookiesApp::Action

      def call(params)
        self.body = 'deleted!'
        cookies[:delete] = nil
      end
    end
  end

end
