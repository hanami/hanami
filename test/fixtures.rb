require 'hanami/model'
require 'hanami/mailer'

class FakeFrameworkConfiguration
  def prefix(value = nil)
    if value.nil?
      @prefix
    else
      @prefix = value
    end
  end

  def suffix(value = nil)
    if value.nil?
      @suffix
    else
      @suffix = value
    end
  end
end

class Order
  include Hanami::Entity

  attributes :size, :coffee, :qty
end

class OrderRepository
  include Hanami::Repository
end

module CoffeeShop
  class Application < Hanami::Application
    configure do
      root   Pathname.new(File.dirname(__FILE__)).join('../tmp/coffee_shop')
      layout nil

      load_paths.clear
      templates 'app/templates'

      default_response_format :html

      security.x_frame_options "DENY"
      security.content_security_policy %{
        form-action 'self';
        referrer origin-when-cross-origin;
        reflected-xss block;
        frame-ancestors 'self';
        base-uri 'self';
        default-src 'none';
        connect-src 'self';
        img-src 'self';
        style-src 'self';
        font-src 'self';
        object-src 'self';
        plugin-types application/pdf;
        child-src 'self';
        frame-src 'self';
        media-src 'self'
      }

      scheme 'https'
      host   'hanami-coffeeshop.org'

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
  class Application < Hanami::Application
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

class TinyApp < Hanami::Application
  configure do
    routes do
      get '/', to: 'home#index'
    end
  end
end

class CSRFAction
  include Hanami::Action
  include Hanami::Action::Session
  include Hanami::Action::CSRFProtection

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

class FilteredParams < Hanami::Action::Params
  param :name
end

class FilteredCSRFAction
  include Hanami::Action
  include Hanami::Action::Session
  include Hanami::Action::CSRFProtection

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
  include Hanami::Action
  include Hanami::Action::Session
  include Hanami::Action::CSRFProtection

  def call(env)
    # ...
  end

  private

  def verify_csrf_token?
    false
  end
end

module ForceSslApp
  class Application < Hanami::Application
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
  class Application < Hanami::Application
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
  class Application < Hanami::Application
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
  class Application < Hanami::Application
    configure do
      routes do
        get '/home',  to: 'home#show', as: :home
        get '/users', to: 'users#index'
        get '/articles', to: 'articles#index'
      end
    end
  end

  module Controllers
    module Home
      class Show
        include Hanami::Action

        def call(params)
          self.body = 'hello Back'
        end
      end
    end
    module Users
      class Index
        include Hanami::Action

        def call(params)
          self.body = 'hello from Back users endpoint'
        end
      end
    end
    module Articles
      class Index
        include Hanami::Action

        def call(params)
          self.body = request.url
        end
      end
    end
  end
end

module Front
  class Application < Hanami::Application
    configure do
      routes do
        get '/home', to: 'home#show', as: :home
      end
    end
  end

  module Controllers
    module Home
      class Show
        include Hanami::Action

        def call(params)
          self.body = 'hello Front'
        end
      end
    end
  end
end
