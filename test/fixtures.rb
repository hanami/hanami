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
