require 'rack'
require 'rack/builder'
require 'hanami/router'
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
      @renderer = Renderer.new

      mount(configuration)
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
    attr_reader :renderer

    # @since 0.9.0
    # @api private
    def mount(configuration)
      @routes = Hanami::Router.new do
        configuration.mounted.each do |klass, app|
          if klass.ancestors.include?(Hanami::Application)
            namespace = Utils::String.namespace(klass.name)
            namespace = Utils::Class.load!("#{namespace}::Controllers")
            configuration = Components["#{app.app_name}.controller"]
            scope(app.path_prefix, namespace: namespace, configuration: configuration, &klass.configuration.routes)
          else
            mount(klass, at: app.path_prefix)
          end
        end
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

      unless Hanami.env?(:test) || routes.defined?
        require 'hanami/welcome'
        builder.use Hanami::Welcome
      end

      builder.use Rack::MethodOverride
    end

    def app
      @app ||= ->(env) { renderer.render(env, routes.call(env)) }
    end
  end
end
