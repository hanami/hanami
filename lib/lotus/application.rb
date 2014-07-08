require 'lotus/utils/class_attribute'
require 'lotus/frameworks'
require 'lotus/configuration'
require 'lotus/loader'
require 'lotus/rendering_policy'
require 'lotus/middleware'

module Lotus
  # A full stack Lotus application
  #
  # @since 0.1.0
  #
  # @example
  #   require 'lotus'
  #
  #   module Bookshelf
  #     Application < Lotus::Application
  #     end
  #   end
  class Application
    # Override Ruby's Class#inherited
    #
    # @since x.x.x
    # @api private
    #
    # @see http://www.ruby-doc.org/core/Class.html#method-i-inherited
    def self.inherited(base)
      super

      base.class_eval do
        include Lotus::Utils::ClassAttribute

        class_attribute :configuration
        self.configuration = Configuration.new
      end
    end

    # Configure the application.
    # It yields the given block in the context of the configuration
    #
    # @param environment [Symbol,nil] the configuration environment name
    # @param blk [Proc] the configuration block
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration
    #
    # @example
    #   require 'lotus'
    #
    #   module Bookshelf
    #     Application < Lotus::Application
    #       configure do
    #         # ...
    #       end
    #     end
    #   end
    def self.configure(environment = nil, &blk)
      configuration.configure(environment, &blk)
    end

    # Return the routes for this application
    #
    # @return [Lotus::Router] a route set
    #
    # @since 0.1.0
    #
    # @see Lotus::Configuration#routes
    attr_reader :routes

    # Set the routes for this application
    #
    # @param [Lotus::Router]
    #
    # @since 0.1.0
    # @api private
    attr_writer :routes

    # Initialize and load a new instance of the application
    #
    # @return [Lotus::Application] a new instance of the application
    #
    # @since 0.1.0
    def initialize
      self.class.load!(self)
      @rendering_policy = RenderingPolicy.new(configuration)
    end

    # Eager load the application configuration, by activating the framework
    # duplication mechanisms.
    #
    # @since 0.1.1
    #
    # @example
    #   require 'lotus'
    #
    #   module OneFile
    #     class Application < Lotus::Application
    #       configure do
    #         routes do
    #           get '/', to: 'dashboard#index'
    #         end
    #       end
    #
    #       load!
    #     end
    #
    #     module Controllers::Dashboard
    #       include OneFile::Controller
    #
    #       action 'Index' do
    #         def call(params)
    #           self.body = 'Hello!'
    #         end
    #       end
    #     end
    #   end
    def self.load!(recipient = self)
      Lotus::Loader.new(recipient).load!
    end

    # Return the configuration for this application
    #
    # @since 0.1.0
    # @api private
    #
    # @see Lotus::Application.configuration
    def configuration
      self.class.configuration
    end

    # Return the application name
    #
    # @since 0.1.1
    # @api private
    def name
      self.class.name
    end

    # Process a request.
    # This method makes Lotus applications compatible with the Rack protocol.
    #
    # @param env [Hash] a Rack env
    #
    # @return [Array] a serialized Rack response
    #
    # @since 0.1.0
    #
    # @see http://rack.github.io
    # @see Lotus::Application#middleware
    def call(env)
      middleware.call(env).tap do |response|
        @rendering_policy.render(response)
      end
    end

    # Rack middleware stack
    #
    # @return [Lotus::Middleware] the middleware stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Lotus::Middleware
    def middleware
      @middleware ||= Lotus::Middleware.new(self)
    end
  end
end
