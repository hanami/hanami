require 'hanami/utils/escape'

module Hanami
  # Routes factory
  #
  # A Hanami application has this factory instantiated by default and associated
  # to the `Routes` constant, under the application namespace.
  #
  # @since 0.1.0
  # @api private
  class Routes
    # Initialize the factory
    #
    # @param routes [Hanami::Router] a routes set
    #
    # @return [Hanami::Routes] the factory
    #
    # @since 0.1.0
    # @api private
    def initialize(routes)
      @routes = routes
    end

    # Return a relative path for the given route name
    #
    # @param name [Symbol] the route name
    # @param args [Array,nil] an optional set of arguments that is passed down
    #   to the wrapped route set.
    #
    # @return [Hanami::Utils::Escape::SafeString] the corresponding relative URL
    #
    # @raise Hanami::Routing::InvalidRouteException
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/hanami-router/Hanami/Router#path-instance_method
    #
    # @example Basic example
    #   require 'hanami'
    #
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Web.routes.path(:login)
    #     # => '/login'
    #
    #   Web.routes.path(:login, return_to: '/dashboard')
    #     # => '/login?return_to=%2Fdashboard'
    #
    # @example Dynamic finders
    #   require 'hanami'
    #
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Web.routes.login_path
    #     # => '/login'
    #
    #   Web.routes.login_path(return_to: '/dashboard')
    #     # => '/login?return_to=%2Fdashboard'
    def path(name, *args)
      Utils::Escape::SafeString.new(@routes.path(name, *args))
    end

    # Return an absolute path for the given route name
    #
    # @param name [Symbol] the route name
    # @param args [Array,nil] an optional set of arguments that is passed down
    #   to the wrapped route set.
    #
    # @return [Hanami::Utils::Escape::SafeString] the corresponding absolute URL
    #
    # @raise Hanami::Routing::InvalidRouteException
    #
    # @since 0.1.0
    #
    # @see http://rdoc.info/gems/hanami-router/Hanami/Router#url-instance_method
    #
    # @example Basic example
    #   require 'hanami'
    #
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           scheme 'https'
    #           host   'bookshelf.org'
    #
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Web.routes.url(:login)
    #     # => 'https://bookshelf.org/login'
    #
    #   Web.routes.url(:login, return_to: '/dashboard')
    #     # => 'https://bookshelf.org/login?return_to=%2Fdashboard'
    #
    # @example Dynamic finders
    #   require 'hanami'
    #
    #   module Web
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           scheme 'https'
    #           host   'bookshelf.org'
    #
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Web.routes.login_url
    #     # => 'https://bookshelf.org/login'
    #
    #   Web.routes.login_url(return_to: '/dashboard')
    #     # => 'https://bookshelf.org/login?return_to=%2Fdashboard'
    def url(name, *args)
      Utils::Escape::SafeString.new(@routes.url(name, *args))
    end

    # Recognize a route from a Rack env.
    #
    # This method is designed for testing purposes
    #
    # @param env [Hash] a Rack env
    #
    # @return [Hanami::Routing::RecognizedRoute] the recognized route
    #
    # @since 0.8.0
    #
    # @see http://hanamirb.org/guides/routing/testing
    #
    # @example Path Generation
    #   # spec/web/routes_spec.rb
    #   RSpec.describe Web::Routes do
    #     it 'generates "/"' do
    #       actual = described_class.path(:root)
    #       expect(actual).to eq '/'
    #     end
    #
    #     it 'generates "/books/23"' do
    #       actual = described_class.path(:book, id: 23)
    #       expect(actual).to eq '/books/23'
    #     end
    #   end
    #
    # @example Route Recognition
    #   # spec/web/routes_spec.rb
    #   RSpec.describe Web::Routes do
    #
    #     # ...
    #
    #     it 'recognizes "GET /"' do
    #       env   = Rack::MockRequest.env_for('/')
    #       route = described_class.recognize(env)
    #
    #       expect(route).to be_routable
    #
    #       expect(route.path).to   eq '/'
    #       expect(route.verb).to   eq 'GET'
    #       expect(route.params).to eq({})
    #     end
    #
    #     it 'recognizes "PATCH /books/23"' do
    #       env   = Rack::MockRequest.env_for('/books/23', method: 'PATCH')
    #       route = described_class.recognize(env)
    #
    #       expect(route).to be_routable
    #
    #       expect(route.path).to   eq '/books/23'
    #       expect(route.verb).to   eq 'PATCH'
    #       expect(route.params).to eq(id: '23')
    #     end
    #
    #     it 'does not recognize unknown route' do
    #       env   = Rack::MockRequest.env_for('/foo')
    #       route = described_class.recognize(env)
    #
    #       expect(route).to_not be_routable
    #     end
    #   end
    def recognize(env)
      @routes.recognize(env)
    end

    protected

    # @since 0.3.0
    # @api private
    def method_missing(m, *args)
      named_route, type = m.to_s.split(/\_(path|url)\z/)

      if type
        public_send(type, named_route.to_sym, *args)
      else
        super
      end
    end
  end
end
