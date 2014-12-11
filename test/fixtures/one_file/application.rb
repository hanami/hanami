module OneFile
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: 'dashboard#index'
      end
    end

    load!
  end

  module Controllers::Dashboard
    class Index
      include OneFile::Action

      def call(params)
        self.body = 'Hello'
      end
    end
  end
end
