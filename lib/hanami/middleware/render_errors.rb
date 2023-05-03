# frozen_string_literal: true

require "rack"

# rubocop:disable Lint/RescueException

module Hanami
  module Middleware
    class RenderErrors
      def initialize(app, enabled, errors_app)
        @app = app
        @enabled = enabled
        @errors_app = errors_app
      end

      def call(env)
        @app.call(env)
      rescue Exception => exception
        request = Rack::Request.new(env)

        if @enabled
          render_exception(request, exception)
        else
          raise exception
        end
      end

      private

      def render_exception(request, exception)
        wrapper = RenderableException.new(exception)

        status = wrapper.status_code
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
