module ExceptionHandler
  class Application < Hanami::Application
    configure do
      routes do
        get '/controller_exception', to: 'exceptional_home#controller_exception'
        get '/view_exception', to: 'exceptional_home#view_exception'
        get '/no_exception', to: 'exceptional_home#no_exception'
      end
    end

    load!
  end
end
