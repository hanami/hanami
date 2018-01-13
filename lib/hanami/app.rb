require 'rack'
require 'rack/builder'
require 'hanami/router'
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
    # Initialize a new instance
    #
    # @param configuration [Hanami::Configuration] general configuration
    # @param environment [Hanami::Environment] current environment
    #
    # @since 0.9.0
    # @api private
    def initialize(configuration, environment)
      Components.resolve('apps')

      @builder = Rack::Builder.new
      @routes  = Hanami::Router.new

      mount(configuration)
      middleware(environment)
      builder.run(routes)
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
    end

    private

    # @since 0.9.0
    # @api private
    attr_reader :builder

    # @since 0.9.0
    # @api private
    attr_reader :routes

    # @since 0.9.0
    # @api private
    def mount(configuration)
      configuration.mounted.each do |klass, app|
        routes.mount(klass, at: app.path_prefix, host: app.host)
      end
    end

    # @since 0.9.0
    # @api private
    def middleware(environment)
      builder.use Hanami::CommonLogger, Hanami.logger unless Hanami.logger.nil?
      builder.use Rack::ContentLength

      if middleware = environment.static_assets_middleware # rubocop:disable Lint/AssignmentInCondition
        builder.use middleware
      end

      builder.use Rack::MethodOverride
    end
  end
end
