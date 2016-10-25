require 'rack'
require 'rack/builder'
require 'hanami/router'
require 'hanami/components'

module Hanami
  # Main application that mounts many Rack and/or Hanami applications.
  #
  # @see Hanami.app
  #
  # @since x.x.x
  # @api private
  class App
    # Initialize a new instance
    #
    # @param configuration [Hanami::Configuration] general configuration
    # @param environment [Hanami::Environment] current environment
    #
    # @since x.x.x
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
    # @since x.x.x
    # @api private
    def call(env)
      builder.call(env)
    end

    private

    # @since x.x.x
    # @api private
    attr_reader :builder

    # @since x.x.x
    # @api private
    attr_reader :routes

    # @since x.x.x
    # @api private
    def mount(configuration)
      configuration.mounted.each do |klass, app|
        routes.mount(klass, at: app.path_prefix)
      end
    end

    # @since x.x.x
    # @api private
    def middleware(environment)
      if middleware = environment.static_assets_middleware # rubocop:disable Lint/AssignmentInCondition
        builder.use middleware
      end

      builder.use Rack::MethodOverride
    end
  end
end
