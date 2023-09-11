# frozen_string_literal: true

require "rack"

# rubocop:disable Lint/RescueException

module Hanami
  module Middleware
    # Rack middleware that rescues errors raised by the app renders friendly error responses, via a
    # given "errors app".
    #
    # By default, this is enabled only in production mode.
    #
    # @see Hanami::Config#render_errors
    # @see Hanani::Middleware::PublicErrorsApp
    #
    # @api private
    # @since 2.1.0
    class RenderErrors
      # @api private
      # @since 2.1.0
      class RenderableException
        attr_reader :exception
        attr_reader :responses

        # @api private
        # @since 2.1.0
        def initialize(exception, responses:)
          @exception = exception
          @responses = responses
        end

        # @api private
        # @since 2.1.0
        def rescue_response?
          responses.key?(exception.class.name)
        end

        # @api private
        # @since 2.1.0
        def status_code
          Rack::Utils.status_code(responses[exception.class.name])
        end
      end

      # @api private
      # @since 2.1.0
      def initialize(app, config, errors_app)
        @app = app
        @config = config
        @errors_app = errors_app
      end

      # @api private
      # @since 2.1.0
      def call(env)
        @app.call(env)
      rescue Exception => exception
        raise unless @config.render_errors

        render_exception(env, exception)
      end

      private

      def render_exception(env, exception)
        request = Rack::Request.new(env)
        renderable = RenderableException.new(exception, responses: @config.render_error_responses)

        status = renderable.status_code
        request.path_info = "/#{status}"
        request.set_header(Rack::REQUEST_METHOD, "GET")

        @errors_app.call(request.env)
      rescue Exception => failsafe_error
        # rubocop:disable Style/StderrPuts
        $stderr.puts "Error during exception rendering: #{failsafe_error}\n  #{failsafe_error.backtrace * "\n  "}"
        # rubocop:enable Style/StderrPuts

        [
          500,
          {"Content-Type" => "text/plain; charset=utf-8"},
          ["Internal Server Error"]
        ]
      end
    end
  end
end

# rubocop:enable Lint/RescueException
