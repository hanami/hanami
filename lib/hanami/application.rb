require 'hanami/utils/class_attribute'
require 'hanami/frameworks'
require 'hanami/configuration'
require 'hanami/loader'
require 'hanami/logger'
require 'hanami/rendering_policy'
require 'hanami/middleware'

module Hanami
  # A full stack Hanami application
  #
  # @since 0.1.0
  #
  # @example
  #   require 'hanami'
  #
  #   module Bookshelf
  #     class Application < Hanami::Application
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
        include Hanami::Utils::ClassAttribute

        class_attribute :configuration
        self.configuration = Configuration.new
      end

      synchronize do
        applications.add(base)
      end
    end

    # Return the routes for this application
    #
    # @return [Hanami::Router] a route set
    #
    # @since 0.1.0
    #
    # @see Hanami::Configuration#routes
    attr_reader :routes

    # Set the routes for this application
    #
    # @param [Hanami::Router]
    #
    # @since 0.1.0
    # @api private
    attr_writer :routes

    # Rendering policy
    #
    # @param [Hanami::RenderingPolicy]
    #
    # @since 0.2.0
    # @api private
    attr_accessor :renderer

    # Initialize and load a new instance of the application
    #
    # @return [Hanami::Application] a new instance of the application
    #
    # @since 0.1.0
    def initialize(options = {})
      self.class.configuration.path_prefix options[:path_prefix]
      self.class.load!(self)
    end

    # Return the configuration for this application
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Application.configuration
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
    # This method makes Hanami applications compatible with the Rack protocol.
    #
    # @param env [Hash] a Rack env
    #
    # @return [Array] a serialized Rack response
    #
    # @since 0.1.0
    #
    # @see http://rack.github.io
    # @see Hanami::RenderingPolicy#render
    # @see Hanami::Application#middleware
    def call(env)
      renderer.render(env, middleware.call(env))
    end

    # Rack middleware stack
    #
    # @return [Hanami::Middleware] the middleware stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Middleware
    def middleware
      @middleware ||= configuration.middleware
    end

    class << self

      # Registry of Hanami applications in the current Ruby process
      #
      # @return [Set] a set of all the registered applications
      #
      # @since 0.2.0
      # @api private
      def applications
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
      # @see Hanami::Configuration
      #
      # @example
      #   require 'hanami'
      #
      #   module Bookshelf
      #     Application < Hanami::Application
      #       configure do
      #         # ...
      #       end
      #     end
      #   end
      def configure(environment = nil, &blk)
        configuration.configure(environment, &blk)
      end

      # Eager load the application configuration, by activating the framework
      # duplication mechanisms.
      #
      # @param application [Hanami::Application, Class<Hanami::Application>]
      # @return void
      #
      # @since 0.1.1
      #
      # @example
      #   require 'hanami'
      #
      #   module OneFile
      #     class Application < Hanami::Application
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
      #       class Index
      #         include OneFile::Action
      #
      #         def call(params)
      #           self.body = 'Hello!'
      #         end
      #       end
      #     end
      #   end
      def load!(application = self)
        Hanami::Loader.new(application).load!
      end

      # Preload all the registered applications, by yielding their configurations
      # and preparing the frameworks.
      #
      # This is useful for testing suites, where we want to make Hanami frameworks
      # ready, but not preload applications code.
      #
      # This allows to test components such as views or actions in isolation and
      # to have faster boot times.
      #
      # @return [void]
      #
      # @since 0.2.0
      def preload!
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
      # @since 0.2.1
      # @api private
      def preload_applications!
        synchronize do
          applications.each { |app| app.new }
        end

        nil
      end

      private

      # Yields the given block in a critical section
      #
      # @since 0.2.0
      # @api private
      def synchronize
        Mutex.new.synchronize do
          yield
        end
      end
    end
  end
end
