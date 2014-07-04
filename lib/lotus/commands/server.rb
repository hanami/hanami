require 'rack'

module Lotus
  module Commands
    class Server < ::Rack::Server
      attr_reader :options

      def initialize(env)
        @options = _extract_options(env)
      end

      # Primarily this removes the ::Rack::Chunked middleware
      # which is the cause of Safari content-length bugs.
      def middleware
        mw = Hash.new { |e, m| e[m] = [] }
        mw["deployment"].concat([::Rack::ContentLength, ::Rack::CommonLogger])
        mw["development"].concat(mw["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
        mw
      end

      private

      def _extract_options(env)
        env.to_options.merge(
          Host:        env.host,
          Port:        env.port,
          AccessLog:   []
        )
      end
    end
  end
end
