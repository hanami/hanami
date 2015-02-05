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
  #     class Application < Lotus::Application
  #     end
  #   end
  class Application
    # Override Ruby's Class#inherited
    #
    # @since 0.2.0
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

      synchronize do
        applications.add(base)
      end
    end

    # Registry of Lotus applications in the current Ruby process
    #
    # @return [Set] a set of all the registered applications
    #
    # @since 0.2.0
    # @api private
    def self.applications
      synchronize do
        @@applications ||= Set.new
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

    # Rendering policy
    #
    # @param [Lotus::RenderingPolicy]
    #
    # @since 0.2.0
    # @api private
    attr_accessor :renderer

    # Initialize and load a new instance of the application
    #
    # @return [Lotus::Application] a new instance of the application
    #
    # @since 0.1.0
    def initialize
      self.class.load!(self)
    end

    # Eager load the application configuration, by activating the framework
    # duplication mechanisms.
    #
    # @param application [Lotus::Application, Class<Lotus::Application>]
    # @return void
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
    def self.load!(application = self)
      Lotus::Loader.new(application).load!
    end

    # Preload all the registered applications, by yielding their configurations
    # and preparing the frameworks.
    #
    # This is useful for testing suites, where we want to make Lotus frameworks
    # ready, but not preload applications code.
    #
    # This allows to test components such as views or actions in isolation and
    # to have faster boot times.
    #
    # @return [void]
    #
    # @since 0.2.0
    def self.preload!
      synchronize do
        applications.each(&:load!)
      end

      nil
    end

    # Full preload for all the registered applications.
    #
    # This is useful in console where we want all the application code available.
    #
    # @return [void]
    #
    # @since x.x.x
    # @api private
    def self.preload_applications!
      synchronize do
        applications.each { |app| app.new }
      end

      nil
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
    # @since 0.2.0
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
      renderer.render(env,
                      middleware.call(env))
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
      @middleware ||= configuration.middleware
    end

    private

    # Yields the given block in a critical section
    #
    # @since 0.2.0
    # @api private
    def self.synchronize
      Mutex.new.synchronize do
        yield
      end
    end
  end
end
