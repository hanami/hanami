require 'rack'

module Lotus
  module Commands
    class Server < ::Rack::Server
      def options
        @options ||= parse_options(ARGV.slice(1..-1))
      end

      # Primarily this removes the ::Rack::Chunked middleware
      # which is the cause of Safari content-length bugs.
      def middleware
        m = Hash.new { |e, m| e[m] = [] }
        m["deployment"].concat([::Rack::ContentLength])
        m["development"].concat(m["deployment"] + [::Rack::ShowExceptions, ::Rack::Lint])
        m
      end
    end
  end
end
