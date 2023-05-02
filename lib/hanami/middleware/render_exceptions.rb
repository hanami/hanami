# frozen_string_literal: true

require "rack"

# rubocop:disable Lint/RescueException

module Hanami
  module Middleware
    class RenderExceptions
      def initialize(app, exceptions_app)
        @app = app
        @exceptions_app = exceptions_app
      end

      def call(env)
        @app.call(env)
      rescue Exception => exception
        request = Rack::Request.new(env)

        if render_exceptions?(request)
          render_exception(request, exception)
        else
          raise exception
        end
      end

      private

      def render_exceptions?(request)
        # TODO: make configurable, store in request
        true
      end

      def render_exception(request, exception)
        wrapper = RenderableException.new(exception)

        status = wrapper.status_code
        request.path_info = "/#{status}"
        request.set_header(Rack::REQUEST_METHOD, "GET")

        @exceptions_app.call(request.env)
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
