require 'thread'
require 'concurrent'
require 'hanami/application_name'
require 'hanami/application_namespace'
require 'hanami/application_configuration'
require 'hanami/environment_application_configurations'
require 'hanami/rendering_policy'

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

      base.extend(ClassMethods)
      base.namespace.module_eval do
        class << self
          # Routes for this application
          #
          # @return [Hanami::Routes] the routes for this Hanami application
          #
          # @since 0.9.0
          # @api public
          #
          # @example
          #
          #   Web.routes
          #   Admin.routes
          attr_accessor :routes
        end
      end
    end

    # Class interface for Hanami applications
    #
    # @since 0.9.0
    # @api private
    module ClassMethods
      # Override Ruby's Class#extended
      #
      # @since 0.9.0
      # @api private
      #
      # @see http://www.ruby-doc.org/core/Class.html#method-i-extended
      def self.extended(base) # rubocop:disable Metrics/MethodLength
        super

        base.class_eval do
          @namespace      = ApplicationNamespace.resolve(name)
          @configurations = EnvironmentApplicationConfigurations.new
          @_lock          = Mutex.new

          class << self
            # @since 0.9.0
            # @api private
            attr_reader :namespace

            # @since 0.9.0
            # @api private
            attr_reader :configurations

            # @since 0.9.0
            # @api private
            attr_reader :configuration
          end
        end
      end

      # Hanami application name
      #
      # @return [String] the Hanami application name
      #
      # @since 0.9.0
      # @api private
      #
      # @example
      #   require 'hanami'
      #
      #   module Web
      #     class Application < Hanami::Application
      #     end
      #   end
      #
      #   Web::Application.app_name # => "web"
      def app_name
        ApplicationName.new(name).to_s
      end

      # Set configuration
      #
      # @param configuration [Hanami::ApplicationConfiguration] the application configuration
      #
      # @raise [RuntimeError] if the configuration is assigned more than once
      #
      # @since 0.1.0
      # @api private
      def configuration=(configuration)
        @_lock.synchronize do
          # raise "Can't assign configuration more than once (#{app_name})" unless @configuration.nil?
          @configuration = configuration
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
      # @see Hanami::ApplicationConfiguration
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
        configurations.add(environment, &blk)
      end
    end

    # Initialize and load a new instance of the application
    #
    # @return [Hanami::Application] a new instance of the application
    #
    # @since 0.1.0
    # @api private
    def initialize
      @renderer   = RenderingPolicy.new(configuration)
      @middleware = configuration.middleware
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

    private

    # Return the configuration for this application
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Application.configuration
    def configuration
      self.class.configuration
    end

    # Rendering policy
    #
    # @since 0.2.0
    # @api private
    #
    # @see Hanami::RenderingPolicy
    attr_reader :renderer

    # Rack middleware stack
    #
    # @return [Hanami::Middleware] the middleware stack
    #
    # @since 0.1.0
    # @api private
    #
    # @see Hanami::Middleware
    attr_reader :middleware
  end
end
