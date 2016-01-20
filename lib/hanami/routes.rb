require 'hanami/utils/escape'

module Hanami
  # Routes factory
  #
  # A Hanami application has this factory instantiated by default and associated
  # to the `Routes` constant, under the application namespace.
  #
  # @since 0.1.0
  class Routes
    # Initialize the factory
    #
    # @param routes [Hanami::Router] a routes set
    #
    # @return [Hanami::Routes] the factory
    #
    # @since 0.1.0
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
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Routes.path(:login)
    #     # => '/login'
    #
    #   Bookshelf::Routes.path(:login, return_to: '/dashboard')
    #     # => '/login?return_to=%2Fdashboard'
    #
    # @example Dynamic finders
    #   require 'hanami'
    #
    #   module Bookshelf
    #     class Application < Hanami::Application
    #       configure do
    #         routes do
    #           get '/login', to: 'sessions#new', as: :login
    #         end
    #       end
    #     end
    #   end
    #
    #   Bookshelf::Routes.login_path
    #     # => '/login'
    #
    #   Bookshelf::Routes.login_path(return_to: '/dashboard')
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
    #   module Bookshelf
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
    #   Bookshelf::Routes.url(:login)
    #     # => 'https://bookshelf.org/login'
    #
    #   Bookshelf::Routes.url(:login, return_to: '/dashboard')
    #     # => 'https://bookshelf.org/login?return_to=%2Fdashboard'
    #
    # @example Dynamic finders
    #   require 'hanami'
    #
    #   module Bookshelf
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
    #   Bookshelf::Routes.login_url
    #     # => 'https://bookshelf.org/login'
    #
    #   Bookshelf::Routes.login_url(return_to: '/dashboard')
    #     # => 'https://bookshelf.org/login?return_to=%2Fdashboard'
    def url(name, *args)
      Utils::Escape::SafeString.new(@routes.url(name, *args))
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
