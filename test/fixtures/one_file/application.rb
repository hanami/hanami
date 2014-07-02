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
    include OneFile::Controller

    action 'Index' do
      def call(params)
        self.body = 'Hello'
      end
    end
  end
end
