require 'lotus/model'

class Order
  include Lotus::Entity

  attributes :size, :coffee, :qty
end

class OrderRepository
  include Lotus::Repository
end

module CoffeeShop
  class Application < Lotus::Application
    configure do
      root   Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop')
      layout nil

      load_paths.clear
      templates 'app/templates'

      scheme 'https'
      host   'lotus-coffeeshop.org'

      routes do
        get '/', to: ->{}, as: :root
      end

      adapter type: :memory, uri: 'memory://localhost'
      mapping do
        collection :orders do
          entity Order

          attribute :id,     Integer
          attribute :size,   String
          attribute :coffee, String
          attribute :qty,    Integer
        end
      end
    end
  end
end

module Reviews
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: ->{}, as: :root
      end
    end
  end
end

class RackApp
  def self.call(env)
    [200, {}, ['Hello from RackApp']]
  end
end

module Backend
  class App
    def self.call(env)
    [200, {}, ['home']]
    end
  end
end

class TinyApp < Lotus::Application
  configure do
    routes do
      get '/', to: 'home#index'
    end
  end
end

class CSRFAction
  include Lotus::Action
  include Lotus::Action::Session
  include Lotus::Action::CSRFProtection

  configuration.handle_exceptions false

  expose :csrf_token

  # Ensure _csrf_token param won't be filtered
  params do
    param :name
  end

  def initialize
    generate_csrf_token
  end

  def call(env)
    # ...
  end

  private

  def set_csrf_token
    session[:_csrf_token] ||= @csrf_token || generate_csrf_token
  end

  def generate_csrf_token
    @csrf_token = super
  end
end

class FilteredParams < Lotus::Action::Params
  param :name
end

class FilteredCSRFAction
  include Lotus::Action
  include Lotus::Action::Session
  include Lotus::Action::CSRFProtection

  expose :csrf_token

  # Ensure _csrf_token param won't be filtered
  params FilteredParams

  def initialize
    generate_csrf_token
  end

  def call(env)
    # ...
  end

  private

  def set_csrf_token
    session[:_csrf_token] ||= @csrf_token || generate_csrf_token
  end

  def generate_csrf_token
    @csrf_token = super
  end
end

class DisabledCSRFAction
  include Lotus::Action
  include Lotus::Action::Session
  include Lotus::Action::CSRFProtection

  def call(env)
    # ...
  end

  private

  def verify_csrf_token?
    false
  end
end

module ForceSslApp
  class Application < Lotus::Application
    configure do
      force_ssl true

      routes do
        get     '/', to: 'home#show'
        post    '/', to: 'home#show'
        put     '/', to: 'home#show'
        patch   '/', to: 'home#show'
        delete  '/', to: 'home#show'
        options '/', to: 'home#show'
      end
    end

    load!
  end

  module Controllers::Home
    class Show
      include ForceSslApp::Action

      def call(params)
        self.body = 'this is the body'
      end
    end
  end
end

module ContainerForceSsl
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: 'home#show'
      end

      force_ssl true

      controller.default_headers({'Strict-Transport-Security' => 'max-age=31536000'})
    end

    load!
  end

  module Controllers
    module Home
      class Show
        include ContainerForceSsl::Action

        def call(params)
          self.body = 'hello ContainerForceSsl'
        end
      end
    end
  end
end

module ContainerNoForceSsl
  class Application < Lotus::Application
    configure do
      routes do
        get '/', to: 'home#show'
      end
    end

    load!
  end

  module Controllers
    module Home
      class Show
        include ContainerNoForceSsl::Action

        def call(params)
          self.body = 'hello ContainerNoForceSsl'
        end
      end
    end
  end
end

module Back
  class Application < Lotus::Application
    configure do
      routes do
        get '/home',  to: 'home#show', as: :home
        get '/users', to: 'users#index'
      end
    end
  end

  module Controllers
    module Home
      class Show
        include Lotus::Action

        def call(params)
          self.body = 'hello Back'
        end
      end
    end
    module Users
      class Index
        include Lotus::Action

        def call(params)
          self.body = 'hello from Back users endpoint'
        end
      end
    end
  end
end

module Front
  class Application < Lotus::Application
    configure do
      routes do
        get '/home', to: 'home#show', as: :home
      end
    end
  end

  module Controllers
    module Home
      class Show
        include Lotus::Action

        def call(params)
          self.body = 'hello Front'
        end
      end
    end
  end
end

