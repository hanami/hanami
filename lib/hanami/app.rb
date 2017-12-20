require 'rack'
require 'rack/builder'
require 'hanami/renderer'
require 'hanami/components'
require 'hanami/common_logger'

module Hanami
  # Main application that mounts many Rack and/or Hanami applications.
  #
  # @see Hanami.app
  #
  # @since 0.9.0
  # @api private
  class App
    require "hanami/app/router"

    # Initialize a new instance
    #
    # @param configuration [Hanami::Configuration] general configuration
    # @param environment [Hanami::Environment] current environment
    #
    # @since 0.9.0
    # @api private
    def initialize(configuration, environment)
      Components.resolve('apps')

      @builder  = Rack::Builder.new
      @routes   = Hanami::App::Router.new(configuration)
      @renderer = Renderer.new
      @configuration = configuration

      middleware(environment)
      builder.run(app)
    end

    # Implements Rack SPEC
    #
    # @param env [Hash] a Rack env
    #
    # @return [Array] a serialized Rack response
    #
    # @since 0.9.0
    # @api private
    def call(env)
      builder.call(env)
    rescue => exception
      _handle_exception(env, exception)
    end

    private

    # @since 0.9.0
    # @api private
    attr_reader :builder

    # @since 0.9.0
    # @api private
    attr_reader :routes

    # @since x.x.x
    # @api private
    attr_reader :configuration

    # @since x.x.x
    # @api private
    attr_reader :renderer

    # @since 0.9.0
    # @api private
    def middleware(environment)
      builder.use Hanami::CommonLogger, Hanami.logger unless Hanami.logger.nil?
      builder.use Rack::ContentLength

      if middleware = environment.static_assets_middleware # rubocop:disable Lint/AssignmentInCondition
        builder.use middleware
      end

      unless Hanami.env?(:test) || routes.defined?
        require 'hanami/welcome'
        builder.use Hanami::Welcome
      end

      builder.use Rack::MethodOverride
    end

    def app
      @app ||= ->(env) { renderer.render(routes.call(env)) }
    end

    def _handle_exception(env, exception)
      env['rack.exception'] = exception

      if configuration.handle_exceptions
        response = Rack::Response.new([], 500)
        renderer.render_error(response)
      else
        raise exception
      end
    end
  end
end
