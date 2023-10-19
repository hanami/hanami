# frozen_string_literal: true

require "erb"

module Hanami
  # @api private
  module Web
    # Middleware that renders a welcome view in fresh Hanami apps.
    #
    # @api private
    # @since 2.1.0
    class Welcome
      # @api private
      # @since 2.1.0
      def initialize(app)
        @app = app
      end

      # @api private
      # @since 2.1.0
      def call(env)
        request_path = env["REQUEST_PATH"] || ""
        request_host = env["HTTP_HOST"] || ""

        template_path = File.join(__dir__, "welcome.html.erb")
        body = [ERB.new(File.read(template_path)).result(binding)]

        [200, {}, body]
      end

      private

      # @api private
      # @since 2.1.0
      def hanami_version
        Hanami::VERSION
      end

      # @api private
      # @since 2.1.0
      def ruby_version
        RUBY_DESCRIPTION
      end
    end
  end
end
