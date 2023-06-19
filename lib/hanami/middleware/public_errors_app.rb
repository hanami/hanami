# frozen_string_literal: true

require "rack"

module Hanami
  module Middleware
    # The errors app given to {Hanami::Middleware::RenderErrors}, which renders a error responses
    # from HTML pages kept in `public/` or as simple JSON structures.
    #
    # @see Hanami::Middleware::RenderErrors
    #
    # @api private
    # @since 2.1.0
    class PublicErrorsApp
      # @api private
      # @since 2.1.0
      attr_reader :public_path

      # @api private
      # @since 2.1.0
      def initialize(public_path)
        @public_path = public_path
      end

      # @api private
      # @since 2.1.0
      def call(env)
        request = Rack::Request.new(env)
        status = request.path_info[1..].to_i
        content_type = request.get_header("HTTP_ACCEPT")

        default_body = {
          status: status,
          error: Rack::Utils::HTTP_STATUS_CODES.fetch(status, Rack::Utils::HTTP_STATUS_CODES[500])
        }

        render(status, content_type, default_body)
      end

      private

      def render(status, content_type, default_body)
        body, rendered_content_type = render_content(status, content_type, default_body)

        [
          status,
          {
            "Content-Type" => "#{rendered_content_type}; charset=utf-8",
            "Content-Length" => body.bytesize.to_s
          },
          [body]
        ]
      end

      def render_content(status, content_type, default_body)
        if content_type.to_s.start_with?("application/json")
          require "json"
          [JSON.generate(default_body), "application/json"]
        else
          [render_html_content(status, default_body), "text/html"]
        end
      end

      def render_html_content(status, default_body)
        path = "#{public_path}/#{status}.html"

        if File.exist?(path)
          File.read(path)
        else
          default_body[:error]
        end
      end
    end
  end
end
